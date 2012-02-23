require 'sqlite3'

class Database
  class Table
    def initialize(sql, table)
      @sql = sql
      @table = table
    end
    
    def data(x, y)
	# Create the data files out of the database values
	output = ""
	@sql.execute "SELECT * FROM #{@table}" do |row|
		xval = row[x]
		yval = row[y]
        	output += "#{xval} #{yval}\n"
	end
	File.open("#{@table}.dat", 'w') do |file|  
  		file.puts output
	end
	return "#{@table}.dat"
    end
  end

  def initialize(file_name)
=begin
    @sql = SQLite3::Database.new ':memory:'
    @sql.execute_batch IO.read(file_name)
=end
	@sql = SQLite3::Database.new 'tmp.db'
	@sql.results_as_hash = true
	@sql.execute_batch IO.read(file_name)
  end  
  
  def [](table)
    Table.new @sql, table
  end
end


class Plot
  attr_accessor :title, :data, :first
  # @data will contain .dat file with datapoints
  # @title will contains title of this particular plot
  # @first is true is plot is the first in a series of plots

  def initialize(title)
    @title = title
    @first = false
  end
  
  def to_gnuplot
	s = ""
	if @first # first plot
		s = "plot \"#{@data}\" title '#{@title}'"
	else
		s = ", \\\n \"#{@data}\" title '#{@title}'"
	end
	s
  end
end

class Graph
  attr_accessor :title, :xlabel, :ylabel, :pdf, :pdftitle
  
  def initialize(title)
    @title = title
    @plots = []
    @pdf = false
    @pdftitle = "pdf_gnuplot"
  end
  
  def plot(title)
    p = Plot.new title
    yield p
    if @plots.empty?
	p.first = true
    end
    @plots.push p
    p
  end
  
  def to_s
    "Graph: #{@title}, #{@xlabel}, #{@ylabel}, #{@plots.count}"
  end
  
  def to_gnuplot
    s = "# overall title
set title \"#{@title}\" \n" # set graph title

    s += "# labels at the axes
set xlabel \"#{@xlabel}\"
set ylabel \"#{@ylabel}\"\n" # set x and y label

    s += "# plot the data\n"
    @plots.each do |plot|
	s += plot.to_gnuplot
    end
    s += "\n"

    if pdf # if user wants graph saved to pdf
    	s += "# output to pdf
set term pdf
set output \"#{@pdftitle}.pdf\"\n"
    else # else directly show graph
	s += "# make sure the graph does not disappeare immediately
pause -1\n"
    end
    s
  end

  def draw
	File.open("dummy.p", 'w') do |file|  
  		file.puts to_gnuplot
	end
	# system "gnuplot dummy.p"
  end
end

def createGraph(title)
  g = Graph.new title
  yield g
  g # return value
end

database = Database.new "myDatabase_basic"

graph = createGraph "Example X" do |graph|
  graph.xlabel = "X-Label"
  graph.ylabel = "Y-Label"

  # graph.pdf = true
  # graph.pdftitle = "newpdf"

  graph.plot "SEQ Plot" do |plot|
    plot.data = database['otr2_udp_in'].data('oml_seq', 'oml_ts_server')
  end
  graph.plot "Data Plot" do |plot|
    plot.data = database['otg2_udp_out'].data('oml_seq', 'oml_ts_server')
  end
end

graph.draw

