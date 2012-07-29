class ImpasseTestPlansController < ImpasseAbstractController
  unloadable

  helper :projects
  include ProjectsHelper

  menu_item :impasse
  before_filter :find_project_by_project_id, :authorize

  def index
    @test_plans_by_version, @versions = Impasse::TestPlan.find_all_by_version(@project, params[:completed])
  end

  def new
    @test_plan = Impasse::TestPlan.new(params[:test_plan])
    if request.post? and @test_plan.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => :tc_assign, :project_id => @project, :id => @test_plan
    end
    @versions = @project.versions
  end

  def show
    @test_plan = Impasse::TestPlan.find(params[:id])
    puts "--------------------"
    p @project
  end

  def edit
    @test_plan = Impasse::TestPlan.find(params[:id])
    @test_plan.attributes = params[:test_plan]
    if (request.post? or request.put?) and @test_plan.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => :show, :project_id => @project, :id => @test_plan
    end
    @versions = @project.versions
  end

  def destroy
    @test_plan = Impasse::TestPlan.find(params[:id])
    if request.post? and @test_plan.destroy
      flash[:notice] = l(:notice_successful_delete)
      redirect_to :action => :index, :project_id => @project
    end
  end

  def tc_assign
    params[:tab] = 'tc_assign'
    @versions = @project.versions
    @test_plan = Impasse::TestPlan.find(params[:id])
  end

  def user_assign
    params[:tab] = 'user_assign'
    @versions = @project.versions
    @test_plan = Impasse::TestPlan.find(params[:id])
  end

  def statistics
    @test_plan = Impasse::TestPlan.find(params[:id])
    params[:tab] = 'statistics'
    if params.include? :type
      @statistics = Impasse::Statistics.__send__("summary_#{params[:type]}", @test_plan.id, params[:test_suite_id])
    else
      params[:type] = "default"
      @statistics = Impasse::Statistics.summary_default(@test_plan.id, params[:test_suite_id])
    end

    respond_to do |format|
      if request.xhr?
        format.html { render :partial => "impasse_test_plans/statistics/#{params[:type]}" }
      else
        format.html
      end
      format.json { render :json => @statistics }
    end
  end

  def add_test_case
    if params.include? :test_case_ids
      new_cases = 0
      nodes = Impasse::Node.find(:all, :conditions => ["id in (?)", params[:test_case_ids]])
      for node in nodes
        test_case_ids = []
        if node.is_test_suite?
          test_case_ids.concat node.all_decendant_cases.collect{|n| n.id}
        else
          test_case_ids << node.id
        end

        for test_case_id in test_case_ids
          test_plan_case =
            Impasse::TestPlanCase.find_or_create_by_test_case_id_and_test_plan_id(
                                                                         :test_case_id => test_case_id,
                                                                         :test_plan_id => params[:test_plan_id],
                                                                         :node_order => 0)
          new_cases += 1
        end
      end
    end

    respond_to do |format|
      format.json { render :json => { :status => 'success', :message => l(:notice_successful_create) } }
    end
  end

  def remove_test_case
    Impasse::TestPlanCase.delete_cascade!(params[:test_plan_id], params[:test_case_id])
    respond_to do |format|
      format.json { render :json => { :status => 'success', :message => l(:notice_successful_delete) } }
    end
  end

  def autocomplete
    @users = @project.users.like(params[:q]).all(:limit => 100)
    render :layout => false
  end
end
