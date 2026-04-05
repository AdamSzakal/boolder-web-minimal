class ProjectListsController < ApplicationController
  before_action :set_project_list, only: %i[show update]

  def create
    @project_list = ProjectList.new(name: params[:name])

    if params[:problem_id].present?
      @project_list.problem_ids = [params[:problem_id].to_i]
    end

    if @project_list.save
      respond_to do |format|
        format.json { render json: { slug: @project_list.slug }, status: :created }
        format.html { redirect_to project_list_path(@project_list) }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @project_list.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: root_path, alert: @project_list.errors.full_messages.to_sentence }
      end
    end
  end

  def show
  end

  # Handles adding/removing problems and renaming
  def update
    if params[:add_problem_id].present?
      id = params[:add_problem_id].to_i
      @project_list.problem_ids |= [id]
    end

    if params[:remove_problem_id].present?
      id = params[:remove_problem_id].to_i
      @project_list.problem_ids -= [id]
    end

    if params[:name].present?
      @project_list.name = params[:name]
    elsif params.key?(:name)
      @project_list.name = nil
    end

    @project_list.save!

    respond_to do |format|
      format.json { render json: { slug: @project_list.slug }, status: :ok }
      format.html { redirect_to project_list_path(@project_list) }
    end
  end

  private

  def set_project_list
    @project_list = ProjectList.find_by!(slug: params[:slug])
  end
end
