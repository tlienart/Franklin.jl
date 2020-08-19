using Franklin
if !(@isdefined msg)
    msg = "franklin-update"
end
publish(prerender=false, final=lunr, message=msg)
