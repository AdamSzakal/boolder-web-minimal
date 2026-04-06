class Boulder < ApplicationRecord
  belongs_to :area

  include CheckConflicts
end
