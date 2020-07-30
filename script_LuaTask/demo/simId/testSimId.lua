
module(...,package.seeall)

require"sim"

sys.taskInit(function()
    sys.wait(10000)
    sim.setId(sim.getId()==0 and 1 or 0, function(result)
        if result then sys.restart("simcross") end
    end)
end)
