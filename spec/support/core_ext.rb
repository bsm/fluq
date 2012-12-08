Celluloid::SupervisionGroup.class_eval do

  def __reset__
    finalize
    sleep(0.001) while actors.any?
    @members.clear
  end

end
