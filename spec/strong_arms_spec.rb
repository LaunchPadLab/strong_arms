require 'spec_helper'

RSpec.describe StrongArms do
  include_context 'user strong arm'

  let!(:params) do
    allowed_params.merge(ignored_params)
  end

  let!(:allowed_params) do
    allowed_user_params.
      merge(allowed_posts_params).
      merge(format_false_with_data_key)
  end

  let!(:allowed_user_params) do
    {
      id: 1,
      name: 'Nate',
      public: false,
      email: required_email_value,
    }
  end

  let!(:format_false_with_data_key) do
    {
      tag: {
        data: {
          id: 1,
        },
      },
    }
  end

  let!(:allowed_posts_params) do
    {
      posts_attributes: [
        first_post_params.merge(allowed_comments_params),
        {
          id: 2,
          title: "Stop Trying to Flip Female Trump Supporters",
          _destroy: true,
        },
      ],
    }
  end

  let!(:first_post_params) do
    { id: 1, title: "Amazon's Smart Doorbell is Creepy as Hell"}
  end

  let!(:allowed_comments_params) do
    {
      comments_attributes: [
        { id: 1, text: "This article is amazing!" },
        { id: 2, text: "This article is trash!", _destroy: true },
      ],
    }
  end

  let!(:ignored_params) do
    {
      created_at: Date.today,
      updated_at: Date.today,
    }
  end

  let!(:parsed_values) do
    {
      :id=>1,
      :name=>"Nate",
      :public=>false,
      :email=>"nate@example.com",
      :posts_attributes=>
      [
        {
          :id=>1,
          :title=>"Amazon's Smart Doorbell is Creepy as Hell",
          :comments_attributes=>[
            {:id=>1, :text=>"This article is amazing!"},
            {:id=>2, :text=>"This article is trash!", :_destroy=>true},
          ]
        },
        {
          :id=>2,
          :title=>"Stop Trying to Flip Female Trump Supporters",
          :_destroy=>true,
        },
      ],
      :tag=>{:id=>1},
    }
  end

  let(:required_email_value) do
    'nate@example.com'
  end

  let!(:required_email_handler) do
    {
      :name=>:email,
      :options=>{ :required => true }, 
      :type=>:input,
    }
  end

  let!(:comments_association_handler) do
    {
      :name=>:comments_attributes,
      :options=>{},
      :type=>:association,
    }
  end

  let!(:tag_association_handler) do
    {:name=>:tag, :options=>{:has_many=>false}, :type=>:association}
  end

  let!(:posts_association_handler) do
    {
      :name=>:posts_attributes,
      :options=>{:has_many=>true},
      :type=>:association,
    }
  end

  let!(:input_handlers) do
    [
      {:name=>:id, :options=>{}, :type=>:input},
      {:name=>:name, :options=>{}, :type=>:input},
      required_email_handler,
      public_boolean_handler,
    ]
  end

  let!(:public_boolean_handler) do
    {:name=>:public, :options=>{}, :type=>:input}
  end

  let!(:profile_handler) do
    {:name=>:profile, :options=>{}, :type=>:input}
  end

  let!(:association_handlers) do
    [
      # comments_association_handler,
      posts_association_handler,
      tag_association_handler,
    ]
  end

  let!(:handlers) do
    input_handlers + association_handlers
  end

  let!(:unexpected_params) do
    { income: 150000 }
  end

  let!(:empty_hash) do
    {}
  end

  let!(:empty_array) do
    []
  end

  let(:strong_arm_with_multiple_input_values) do
    strong_arm.permit(%i[month year])
  end

  let!(:strong_arm) do
    UserStrongArm
  end

  it "has a version number" do
    expect(StrongArms::VERSION).not_to be nil
  end

  describe '.flex' do
    context 'when a non empty hash is passed' do
      it 'returns a hash of flexed permit & association values' do
        result = strong_arm.flex(params)
        expect(result).to eq parsed_values
      end
    end

    context 'when multiple attributes are defined for a single input' do
      it 'raises ArgumentError with a message' do
        message =
          "UserStrongArm recieved multiple attributes for a single input."
        expect { strong_arm_with_multiple_input_values }.
          to raise_exception(ArgumentError, message)
      end
    end

    context 'when unhandled keys are supplied' do
      it 'raises UnhandledKeys with a message' do
        expect { strong_arm.flex(unexpected_params) }.
          to raise_exception(Errors::UnhandledKeys,
            'UserStrongArm received unhandled keys: income.')
      end
    end

    context 'when a empty hash is passed' do
      it 'raises ArgumentError with a message' do
        expect { strong_arm.flex(empty_hash) }.
          to raise_exception(ArgumentError, 'No values were passed.')
      end
    end
  end

  describe '.reduce_handlers' do
    context 'when handlers are present' do
      it 'returns a reduced hash of parsed input values' do
        result = strong_arm.reduce_handlers(handlers, params)
        expect(result).to eq parsed_values
      end
    end

    context 'when handlers are not present' do
      it 'returns an empty hash' do
        result = strong_arm.reduce_handlers(empty_array, params)
        expect(result).to eq empty_hash
      end
    end
  end

  describe '.extract_handler_values_and_parse' do
    context 'when public boolean value is false' do
      it 'returns a parsed public boolean hash' do
        result = strong_arm.
          extract_handler_values_and_parse(public_boolean_handler, params)
        expect(result).to eq(public: false)
      end
    end

    context 'when a required value is missing' do
      let(:required_email_value) { nil }
      let(:result) do
        strong_arm.
          extract_handler_values_and_parse(required_email_handler, params)
      end
      it 'raises an ArgumentError with a message' do
        expect { result }.to raise_exception(ArgumentError,
          'No value for required input: email.')
      end
    end
  end

  describe '.handlers_values' do
    context 'when params are defined' do
      it 'returns a array of input handlers' do
        result = strong_arm.handlers_values
        expect(result).to eq handlers
      end
    end
  end

  describe '.unhandled_keys' do
    context 'when unexpected params are passed' do
      it 'raises UnhandledKeys with a message' do
        expect { strong_arm.flex(unexpected_params) }.
          to raise_exception(Errors::UnhandledKeys)
      end
    end
  end
end
