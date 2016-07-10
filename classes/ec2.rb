# class EC2
class EC2
  def initialize(ec2_config, region, key_name = nil, full_key_name = nil)
    @ec2_config    = ec2_config
    @region        = region
    @key_name      = key_name
    @full_key_name = full_key_name
  end

  def run_proxy_instance
    return if proxy_instance
    create_proxy_key_pair
    run_instance
    create_tag
    wait_until(:instance_status_ok, run_instance.instance_id)
  end

  def public_ip_address
    proxy_instance.public_ip_address
  end

  def terminate_proxy_instance(demon)
    delete_key_pair
    return unless proxy_instance
    terminate_instance
    return if demon
    wait_until(:instance_terminated, proxy_instance.instance_id)
  end

  def exists_proxy_instance?
    !proxy_instance.nil?
  end

  private

  def ec2
    @ec2 ||= Aws::EC2::Client.new
  end

  def wait_until(task, instance_id)
    ec2.wait_until(task.to_sym, instance_ids: [ instance_id ]) do |w|
      w.interval = 5
      w.max_attempts = 100
    end
  end

  def proxy_instance
    return @proxy_instance if @proxy_instance
    @proxy_instance = nil
    ec2.describe_instances.reservations.each do |instances|
      instances.instances.each do |ins|
        @proxy_instance = ins if ins.state.name == 'running' && ins.tags.any? { |tag| tag.value == 'proxy' }
      end
    end
    @proxy_instance
  end

  def amazon_linux_latest_image
    latest = amazon_linux_images[0]
    amazon_linux_images.each do |a|
      ad = DateTime.parse(a.creation_date)
      ld = DateTime.parse(latest.creation_date)
      latest = a if ad > ld
    end
    latest
  end

  def amazon_linux_images
    @amazon_linux_images ||= describe_images.images.map do |image|
      image if image.description && image.description.include?('Amazon Linux')
    end.compact
  end

  def describe_images
    @describe_images ||= ec2.describe_images(@ec2_config['amazon_linux_image_attributes'])
  end

  def proxy_vpc
    @proxy_vpc ||= ec2.describe_vpcs.data.vpcs.select do |vpc|
      vpc.tags.any? { |tag| tag.value == 'proxy_vpc' }
    end.first
  end

  def proxy_subnet
    @proxy_subnet ||= ec2.describe_subnets.data.subnets.select do |subnet|
      subnet.tags.any? { |tag| tag.value == 'proxy' }
    end.first
  end

  def proxy_security_group
    @proxy_sg ||= ec2.describe_security_groups.data.security_groups.select do |sg|
      sg.tags.any? { |tag| tag.value == 'proxy' }
    end.first
  end

  def create_proxy_key_pair
    delete_key_pair
    create_key_pair
  end

  def create_key_pair
    proxy_key = ec2.create_key_pair(key_name: @key_name)
    File.write(@full_key_name, proxy_key.key_material)
    `chmod 400 #{@full_key_name}`
  end

  def delete_key_pair
    ec2.delete_key_pair(dry_run: false, key_name: @key_name)
    FileUtils.rm(@full_key_name, { force: true })
  end

  def run_instance
    @run_instance ||= ec2.run_instances(
      dry_run: false,
      image_id: amazon_linux_latest_image.image_id,
      key_name: @key_name,
      min_count: 1,
      max_count: 1,
      instance_type: @ec2_config['instance_type'],
      placement: { availability_zone: "#{@region}a" },
      network_interfaces: [{ device_index: 0,
                             subnet_id: proxy_subnet.subnet_id,
                             groups: [proxy_security_group.group_id],
                             delete_on_termination: true,
                             associate_public_ip_address: true }]
    ).instances.first
  end

  def create_tag
    ec2.create_tags(resources: [run_instance.instance_id], tags: [ { key: 'Name', value: 'proxy' } ])
  end

  def terminate_instance
    ec2.terminate_instances(
      dry_run: false,
      instance_ids: [proxy_instance.instance_id]
    )
  end
end
