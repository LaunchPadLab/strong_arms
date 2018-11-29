# Strong Arms

A nested parameters friendly alternative to [strong_parameters](https://github.com/rails/strong_parameters) found in Rails.

We love `strong_parameters`, but wanted a cleaner approach for handling deeply nested parameters.

`permit()` is great for handling a few parameters, but becomes tough to read and prone to user error when describing a deeply nested structure.

`require()` is great for ensuring top level keys are present, but does not provide a great interface for flagging specific nested parameters.

Strong Arms provides an interface which makes declaring nested relationships easy, in addition to whitelisting parameters with `permit`, `require` and `ignore`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'strong_arms'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install strong_arms

## Usage

**Controller Definition**

```ruby

class PostController < ApplicationController
  def create
    post = Post.create(post_params)
    render json: post
  end

  def update
    post = Post.find(params[:id])
    post.update(post_params)
    render json: post
  end

  private

  def post_params
    PostStrongArm.flex(params[:post])
  end
end
```

**Strong Arms Definition**

```ruby
# app/strong_arms

class PostStrongArm
  ignore :created_at, :updated_at

  permit :id
  permit :title
  permit :description
  permit :user_id, required: true

  many_nested :comments
end

class CommentStrongArm
  ignore :created_at, :updated_at

  permit :id
  permit :body
  permit :user_id, required: true
end
```

## Permitting Parameters

Permitted parameters are defined in Strong Arms with the `permit` method.

If parameters are passed to Strong Arms without being permitted, Strong Arms will raise an exception.

```ruby
class UserStrongArm
  permit :id
end
```

## Requiring Parameters

Permitted parameters can be "required", by passing the `:required` option.

When required, Strong Arms expects parameter data to be present. 

If it is absent, Strong Arms will raise an exception.

```ruby
class UserStrongArm
  permit :id
  permit :email, required: true
end
```

## Ignoring Parameters

Parameters passed to Strong Arms can be ignored, with the `ignore` method.

Commonly ignored parameters include auto incremented or optional (nillable) values.

```ruby
class UserStrongArm
  ignore :created_at, :updated_at

  permit :id
  permit :email, required: true
end
```

## Nested Parameters

StrongArm handles nested parameters, by specifying a relationship with `many_nested` or `one_nested` methods.

This is similar to how Rails handles association declarations with `has_many` and `has_one` methods.

```ruby
class UserStrongArm
  ignore :created_at, :updated_at

  permit :id
  permit :email, required: true

  many_nested :posts # has_many :posts
  one_nested :profile # has_one :profile
end

class PostStrongArm
  ignore :created_at, :updated_at

  permit :id
  permit :title
  permit :user_id, required: true
end

class ProfileStrongArm
  ignore :created_at, :updated_at

  permit :id
  permit :name
  permit :birthday
  permit :user_id, required: true
end
```

Strong Arms expects nested parameters to follow the `accepts_nested_attributes_for` convention.

```ruby
  many_nested :posts # { posts_attributes: [] }
  one_nested :profile # { profile_attributes: {} }
```

If you do not wish to use `accepts_nested_attributes_for`, provide the `:format` option.

```ruby
  many_nested :posts, format: false # { posts: [] }
  one_nested :profile, format: false # { profile: {} }
```

If Strong Arms cannot find the relevant Strong Arms class for the nested resource, it will raise an exception.



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/launchpadlab/strong_arms. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Strong Arms project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/launchpadlab/strong_arms/blob/master/CODE_OF_CONDUCT.md).
