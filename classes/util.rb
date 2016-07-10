# module Util
module Util
  def self.load_yaml(file_name, path = 'config')
    YAML.load(ERB.new(File.read(
      Dir.glob("#{File.expand_path("../../#{path}", __FILE__)}/#{file_name}")[0]
    )).result)
  end

  def self.optimize_line(str, len)
    diff = len - str.length
    return " #{str[0, len]} :" if diff <= 0
    "#{str}#{' ' * diff}"
  end
end
