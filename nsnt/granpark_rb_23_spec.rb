require "rspec"
require "pry"; require "pry-debugger"

describe "#resolve(size, area)" do
  it "returns 0 for given 1x1 area" do
    size = "11"
    area = <<EOF
0
EOF

    resolve(size, area).should == 0
  end

  it "returns 1 for given 2x2 area" do
    size = "22"
    area = <<EOF
11
10
EOF

    resolve(size, area).should == 1
  end

  it "returns 5 for given 3x3 area" do
    size = "33"
    area = <<EOF
101
010
101
EOF

    resolve(size, area).should == 5
  end

  it "returns 2 for given 6x4 area" do
    size = "64"
    area = <<EOF
100111
100101
100110
111101
EOF

    resolve(size, area).should == 2
  end

  it "returns 2 for given 6x5 area" do
    size = "65"
    area = <<EOF
111111
100001
101101
100001
111111
EOF

    resolve(size, area).should == 2
  end
end

def resolve(size, area)
  area = Area.new(size, area)
  serial = 0
  colonies = {}
  # binding.pry

  area.rownum.times do |ridx|
    area.colnum.times do | cidx|
      here = [ridx, cidx]
      next if area.get(here) == "0"

      surrounding_cells = area.surroundings(here)
      colony_cells = surrounding_cells.select { |pos| area.colony?(pos) }
      non_colony_cells = surrounding_cells - colony_cells

      update_cells = lambda do |cells, val|
        cells.map do |pos|
          unless area.get(pos) == "0"
            area.set(pos, val)
            colonies[val] << pos
          end
        end
      end

      colonies_found = colony_cells.map { |pos| area.get(pos) }
      if colonies_found.size == 0
        serial += 1
        area.set(here, serial)
        colonies[serial] = [here]
        update_cells.call(non_colony_cells, serial)
      elsif colonies_found.size == 1
        new_colony_id = colonies_found.first
        current_colony_id = area.get(here) if area.colony?(here)
        colonies_to_update = nil
        if new_colony_id < current_colony_id
          colonies_to_update = current_colony_id
        elsif current_colony_id < new_colony_id
          colonies_to_update = new_colony_id
          new_colony_id = current_colony_id
        end
        colonies_to_update.each do |colony|
          update_cells.call(colony, new_colony_id)
          colonies[new_colony_id].merge(colonies.delete!(colony))
        end if colonies_to_update
        area.set(here, new_colony_id)
        update_cells.call(non_colony_cells, new_colony_id)
      else
        new_colony_id = colonies_found.min
        current_colony_id = area.get(here) if area.colony?(here)
        colonies_to_update = colonies_found - [new_colony_id]
        if new_colony_id < current_colony_id
          colonies_to_update << current_colony_id
        elsif current_colony_id < new_colony_id
          colonies_to_update << new_colony_id
          new_colony_id = current_colony_id
        end
        colonies_to_update.each do |colony_id|
          update_cells.call(colonies[colony_id], new_colony_id)
          # binding.pry
          colonies.delete(colony_id)
        end if colonies_to_update
        area.set(here, new_colony_id)
        update_cells.call(non_colony_cells, new_colony_id)
      end
    end
  end

  p colonies
  return colonies.size
end

def surrounding_status(row, col)
  up    = [row - 1, col]
  down  = [row + 1, col]
  left  = [row, col - 1]
  right = [row, col + 1]
  [up, down, left, right]
end

class Area
  attr_reader :rownum, :colnum
  attr_accessor :rows

  def initialize(meta, data)
    @colnum, @rownum = meta.split("").map {|meta| meta.to_i}
    @rows = []
    data.split("\n").each { |rowstr| @rows << rowstr.split("") }
  end

  def get(pos)
    row, col = parse_position_argument(pos)
  rescue RangeError
    return "0"
  else
    return @rows[row][col]
  end

  def set(pos, val)
    row, col = parse_position_argument(pos)
    @rows[row][col] = val
  end

  def colony?(pos)
    row, col = parse_position_argument(pos)
  rescue RangeError
    return false
  else
    return (@rows[row][col].class <= Integer)
  end

  def surroundings(pos)
    row, col = parse_position_argument(pos)

    up    = [row - 1, col]
    down  = [row + 1, col]
    left  = [row, col - 1]
    right = [row, col + 1]
    [up, down, left, right]
  end

  private

  def parse_position_argument(pos)
    raise TypeError.new("Cell position must be Array of 2 integer") if (
      (pos.class != Array) ||
      (pos.size != 2) ||
      (pos.select { |elem| not (elem.class <= Fixnum) }.size != 0)
    )
 
    raise RangeError.new("No such cell") if (
      (pos.first < 0) ||
      (pos.first >= @rownum) ||
      (pos.last < 0) ||
      (pos.last >= @colnum)
    )

    return pos.first, pos.last
  end
end
