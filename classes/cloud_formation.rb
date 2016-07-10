# class CloudFormation
class CloudFormation
  def initialize(template = nil)
    @template = template
  end

  def create_or_update_proxy_stack
    check_template
    stack.exists? ? update_stack : create_stack
  end

  def delete_proxy_stack(demon)
    delete_stack(demon) if stack.exists?
  end

  private

  def cf
    @cf ||= Aws::CloudFormation::Client.new
  end

  def stack
    @stack ||= Aws::CloudFormation::Stack.new(stack_name)
  end

  def stack_name
    @stack_name ||= 'proxy'
  end

  def wait_until(task)
    cf.wait_until(task.to_sym, stack_name: stack_name) do |w|
      w.max_attempts = 100
      w.delay = 5
    end
  end

  def check_template
    cf.validate_template(template_body: @template)
  rescue Aws::CloudFormation::Errors::ValidationError => e
    puts e.message
    exit
  end

  def update_stack
    cf.update_stack(stack_name: stack_name, template_body: @template)
    wait_until(:stack_update_complete)
  rescue Aws::CloudFormation::Errors::ValidationError => e
    puts e.message
  end

  def create_stack
    cf.create_stack(stack_name: stack_name, template_body: @template, on_failure: 'DO_NOTHING')
    wait_until(:stack_create_complete)
  end

  def delete_stack(demon)
    cf.delete_stack(stack_name: stack_name)
    return if demon
    wait_until(:stack_delete_complete)
  end
end
