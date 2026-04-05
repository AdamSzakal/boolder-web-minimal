class ProjectList < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  validates :name, length: { maximum: 100 }, allow_blank: true

  before_validation :generate_slug, on: :create

  def problems
    return Problem.none if problem_ids.blank?

    Problem.where(id: problem_ids).index_by(&:id).then do |indexed|
      problem_ids.filter_map { |id| indexed[id] }
    end
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug ||= SecureRandom.urlsafe_base64(8)
  end
end
