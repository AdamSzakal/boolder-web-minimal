class SteepnessesController < ApplicationController
  ALLOWED_VALUES = Problem::STEEPNESS_VALUES - %w[other]
  SORT_OPTIONS = %w[popularity grade]
  GRADE_LEVELS = %w[beginner level4 level5 level6 level7]
  GRADE_RANGES = {
    "beginner" => %w[1a 1a+ 1b 1b+ 1c 1c+ 2a 2a+ 2b 2b+ 2c 2c+ 3a 3a+ 3b 3b+ 3c 3c+],
    "level4" => %w[4a 4a+ 4b 4b+ 4c 4c+],
    "level5" => %w[5a 5a+ 5b 5b+ 5c 5c+],
    "level6" => %w[6a 6a+ 6b 6b+ 6c 6c+],
    "level7" => %w[7a 7a+ 7b 7b+ 7c 7c+]
  }.freeze

  def index
    @steepness = params[:steepness].in?(ALLOWED_VALUES) ? params[:steepness] : nil
    @grade_level = params[:grade_level].in?(GRADE_LEVELS) ? params[:grade_level] : nil
    @direction = params[:direction] == "asc" ? :asc : :desc

    @areas = Area.where(published: true).order(:name)
    @area_id = params[:area_id].present? ? params[:area_id].to_i : nil

    @circuits = Circuit.all.select { |c| c.problems.any? }.sort_by { |c| [c.main_area&.name.to_s, c.average_grade] }
    @circuit_id = params[:circuit_id].present? ? params[:circuit_id].to_i : nil

    @sort = @circuit_id.present? ? "circuit_order" : (params[:sort].in?(SORT_OPTIONS) ? params[:sort] : "popularity")

    @problems = Problem.joins(:area).where(area: { published: true })

    # When browsing a specific circuit, show all problems; otherwise only show popular ones
    @problems = @problems.significant_ascents unless @circuit_id.present?

    @problems = @problems.where(steepness: @steepness) if @steepness.present?
    @problems = @problems.where(grade: GRADE_RANGES[@grade_level]) if @grade_level.present?
    @problems = @problems.where(area_id: @area_id) if @area_id.present?
    @problems = @problems.where(circuit_id: @circuit_id) if @circuit_id.present?

    @problems = case @sort
    when "grade"
      @problems.order(grade: @direction, popularity: :desc)
    when "circuit_order"
      nulls = @direction == :asc ? "LAST" : "FIRST"
      @problems.order(Arel.sql("circuit_number::integer #{@direction.upcase} NULLS #{nulls}"), popularity: :desc)
    else
      @problems.order(popularity: @direction)
    end

    @problems = @problems.limit(100)
  end
end
