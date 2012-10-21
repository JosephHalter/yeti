# Yeti

Yeti: Context, Editor and Search patterns

Editor pattern simplifies edition of multiple objects at once using ActiveModel

## Installation

Add this line to your application's Gemfile:

    gem 'yeti'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yeti

## Usage

### Yeti::Context

The context object allow to communicate application state coming from the
controllers. First, let's create a Context class tuned to your application
logic.

```ruby
class Context < Yeti::Context
  def initialize(hash)
    super hash
    @section = hash.fetch :section
  end

  def in_admin?
    section==:admin

  def api_call?
    section==:api
  end
end
```

Typical usage in controller:

```ruby
class Admin::BaseController < ApplicationController
private
  def current_context
    Context.new account_id: session[:account_id, section: :admin
  end
end
class Admin::UsersController < Admin::BaseController
  def index
    @users = UserSearch.new context, params
  end

  def show
    @user = UserViewer.new context, params[:id]
  end

  def new
    user
  end

  def create
    if user.update_attributes params[:user]
      redirect_to action: :index, notice: t(:successfully_created)
    else
      flash.now[:error] = t(:please_fix_errors_and_retry)
      render :new
    end
  end

  def edit
    user
  end

  def update
    if user.update_attributes params[:user]
      redirect_to action: :index, notice: t(:successfully_updated)
    else
      flash.now[:error] = t(:please_fix_errors_and_retry)
      render :edit
    end
  end

  def user
    @user ||= UserEditor.new context, params[:id]
  end
end
```

The presenters can then use the context to restrict search results, change
validation, etc. The context object is also useful to track current account in
order to apply permissions or know who is performing the action.

Let's say you have a Account model:

```ruby
class Account < ActiveRecord::Base
  def guest?
    false
  end
end
```

of course it could be using Sequel, Mongoid or the ORM of your liking. Then you
can define your context class this way:

```ruby
class Context < Yeti::Context
  class NoAccount < Yeti::Context::NoAccount
    def guest?
      true
    end
  end
  delegate :guest?, to: :account

private

  def find_account_by_id(id)
    Account.find_by_id id
  end

  def no_account
    NoAccount.new
  end
end
```

And with that setup you get:

```ruby
existing_account_id = 1
invalid_id = 2
Context.new.guest? #=> true
Context.new(account_id: existing_account_id).guest? #=> false
Context.new(account_id: invalid_id).guest? #=> true
```

No more passing tons of variables from presenters to presenters, the context
object regroups and unify this communication while being easy to test in
isolation.

### Yeti::Search

### Yeti::Editor

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
