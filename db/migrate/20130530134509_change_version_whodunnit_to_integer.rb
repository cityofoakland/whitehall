class ChangeVersionWhodunnitToInteger < ActiveRecord::Migration
  def up
    connection.execute(%q{
      alter table versions
      alter column whodunnit
      type integer using cast(whodunnit as integer)
    })
  end
  def down
    #noop
  end
end
