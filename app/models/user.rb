class User < ActiveRecord::Base
  has_many :artificial_intelligences
  has_many :artificial_intelligence_games, :through=>:artificial_intelligences

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  # Virtual attribute for sign in
  attr_accessor :login

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :username, :email, :password, :password_confirmation, :remember_me

  validates :username, :presence=>true, :uniqueness=>true, :length => { :minimum => 4, :maximum => 100 }

  def score
    self.artificial_intelligence_games.map(&:score).to_stat.average
  end

  def game_ids
    self.artificial_intelligence_games.map(&:game_id).uniq
  end

  protected
    def self.find_for_database_authentication warden_conditions
     conditions = warden_conditions.dup
     login = conditions.delete(:login)
     where(conditions).where(["username = :value OR email = :value", { :value => login }]).first
   end
end
