class User < ApplicationRecord
  # Convierte el email a minúsculas antes de guardarlo para asegurar la unicidad.
  before_save { self.email = email.downcase }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  has_secure_password
end