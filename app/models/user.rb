class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates_presence_of :username
  validates_uniqueness_of :username
  # validates :username, length: { maximum: 14,
  #                                too_long: "is too long. %{count} characters is the maximum allowed" }

  has_many :books

  has_many :favorite_books
  has_many :favorites, through: :favorite_books, source: :book

  after_create :send_admin_notification
  after_create :send_user_welcome

  def send_admin_notification
    AdminNotifications.new_user_email(self).deliver_now if Rails.env.production?
  end

  def send_user_welcome
    UserNotifications.welcome_new_user(self).deliver_now if Rails.env.production?
  end

  def authored_books
      books.order("created_at DESC").to_a
  end

  before_destroy :clear_books
  def clear_books
    Book.where(user_id: self.id).delete_all
  end
end
