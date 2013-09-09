class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :locale
  before_filter :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for resource_or_scope
    if resource_or_scope.is_a?( User ) && resource_or_scope.locale && resource_or_scope.locale !=  I18n.locale
      I18n.locale = resource_or_scope.locale
    end

    super
  end

  def ensure_logged_in
    redirect_to new_session_path(:user), :alert => "Please log in to create a tournament" unless current_user
  end

  protected
  def locale
    if params[:locale]
      if I18n.available_locales.include?( params[:locale].to_sym )
        # session
        session[:locale] = params[:locale]

        # user
        if current_user
          current_user.update_attribute :locale, params[:locale]
        end
      end
    end

    I18n.locale = session[:locale] || I18n.default_locale
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :username
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :password, :remember_me) }
  end
end
