function(a, b)
    local Sort = aura_env.child_envs[1].config.sorting
    local SortFunc =  aura_env.child_envs[1].sortForSettings -- uses < or > depending on custom options
    if not SortFunc then return end
    local A = a.region.state
    local B = b.region.state
    
    
    local Time = GetTime()
    if Sort.sortCD == 2 then
        if A.expirationTime <= Time and B.expirationTime <= Time then
            if A.class and B.class and A.class ~= B.class then
                
                return SortFunc(Sort.Classes[A.class], Sort.Classes[B.class])
            else
                return SortFunc(A.name,B.name)
            end          
        elseif A.expirationTime < Time and B.expirationTime> Time then
            return Sort.sortType==2 and true or false
        elseif  A.expirationTime > Time and B.expirationTime< Time then
            return Sort.sortType==1 and true or false
        else
            
            return SortFunc(A.expirationTime,B.expirationTime)           
        end       
    else
        if A.class ~= B.class then
            return SortFunc(Sort.Classes[A.class], Sort.Classes[B.class])
        else
            return SortFunc(A.name,B.name)
        end
    end     
end