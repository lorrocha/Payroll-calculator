require 'CSV'
require 'pry'
class CsvReader
  def initialize(file)
    @file = file
  end

  def parse
    temp_array = []
    CSV.foreach(@file, headers:true) do |row|
      temp_array << row
    end
    temp_array
  end
end


class Employee
  @@tax = 0.3

  attr_reader :name, :net_pay

  def initialize(row)
    @name = row["name"]
    @type = row["type"]
    @salary = row["salary"]
    @commibonus = row["commibonus"]
    @quota = row["quota"]
  end

  def calculate_monthly_salary
    format_number(@salary.to_f/12)
  end

  def calculate_net_pay
    format_number(calculate_monthly_salary.to_f - (calculate_monthly_salary.to_f * @@tax))
  end

  def format_number(num)
    sprintf('%0.2f', num)
  end

end

class Owner < Employee

  def calculate_net_pay
    super.to_f + (bonus - (bonus*@@tax))
  end

  def get_csv(file)
    @sales = file
  end

  def check_bonus?
    Sale.new(@sales).monthly_sales > 250000
  end

  def bonus
    @commibonus.to_f if check_bonus?
  end

end

class Commission < Employee
  def calculate_net_pay
    super.to_f + (determine_commission - (determine_commission*@@tax))
  end

  def determine_commission
    @commibonus.to_f*Sale.new(@sales).monthly_sales(@name).to_f
  end

  def get_csv(sales)
    @sales = sales
  end
end

class Quota < Employee

  def calculate_net_pay
    super.to_f + (bonus - (bonus*@@tax))
  end

  def get_csv(sales)
    @sales = sales
  end

  def bonus
    check_bonus? ? @commibonus.to_f : 0
  end

  def check_bonus?
    Sale.new(@sales).monthly_sales(@name).to_f >= @quota.to_f
  end
end

class Sale
  def initialize(file)
    @sales = CsvReader.new(file).parse
  end

  def monthly_sales(name=nil)
    if name.nil?
      @gross_sales = []
      @sales.each do |row|
        @gross_sales << row["gross_sale_value"].to_f
      end
      @gross_sales.reduce(:+)
    else
      temp_array = []
      @sales.each do |row|
        temp_array << row["gross_sale_value"].to_f if row["last_name"] == name.split(' ')[1]
      end
      temp_array.reduce(:+)
    end
  end
end

class Payroll

  attr_reader :employees

  def initialize(sales,employeesfile)
    @sales = sales
    @employeesfile = employeesfile
    @employees = {}
  end

  def populate_employees
    employees = CsvReader.new(@employeesfile).parse
    employees.each do |row|
      var = row["type"]

      if var == "owner"
        @employees[row["name"]] = Owner.new(row)
        @employees[row["name"]].get_csv(@sales)
      elsif var == "commission"
        @employees[row["name"]] = Commission.new(row)
        @employees[row["name"]].get_csv(@sales)
      elsif var == "quota"
        @employees[row["name"]] = Quota.new(row)
        @employees[row["name"]].get_csv(@sales)
      else
        @employees[row["name"]] = Employee.new(row)
      end
    end
    @employees
  end

  def list_employees
    puts @employees.keys
  end

  def find_monthly_gross
    puts Sale.new(@sales).monthly_sales
  end

  def monthly_salary(employee)
    monthly_salary unless @employees.include?(employee)
    puts "***#{@employees[employee].name}***"
    puts "Gross Salary: $#{@employees[employee].calculate_monthly_salary}"
    puts "Commission: $#{@employees[employee].determine_commission}" if @employees[employee].class == Commission
    puts "Bonus: $#{@employees[employee].bonus}" if @employees[employee].class == Owner || @employees[employee].class == Quota
    puts "Net Pay: $#{@employees[employee].calculate_net_pay}"
    puts "--------------------"
  end
end

powerplant = Payroll.new('sales_data.csv','employees.csv')
powerplant.populate_employees
powerplant.list_employees
puts '~~~~~~~~~~~~~~~'
powerplant.find_monthly_gross
powerplant.monthly_salary("Bob Lob")
powerplant.monthly_salary("Jimmy McMahon")
powerplant.monthly_salary("Charles Burns")
powerplant.monthly_salary("Clancy Wiggum")



