Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :executions, only: %i[index show], param: :work_order_id do
        member do
          patch :start
          patch :complete
          patch "items/:line_item_id/start", action: :start_item, as: :start_item
          patch "items/:line_item_id/finish", action: :finish_item, as: :finish_item
        end
      end
    end
  end

  mount Rswag::Api::Engine => "/api-docs"
  mount Rswag::Ui::Engine => "/api-docs"
end
