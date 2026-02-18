# frozen_string_literal: true

module Users
  class ProfilesController < ApplicationController
    before_action :authenticate_user!

    # GET /users/profile
    def show
      @user = current_user
    end

    # POST /users/activate_demo_subscription
    def activate_demo
      current_user.update!(
        plan_code: "paid",
        paid_until: 30.days.from_now
      )
      redirect_to user_profile_path, notice: "Демо-подписка активирована на 30 дней!"
    end

    # POST /users/cancel_subscription
    def cancel
      current_user.update!(
        plan_code: "auth",
        paid_until: nil
      )
      redirect_to user_profile_path, notice: "Подписка отменена."
    end
  end
end
