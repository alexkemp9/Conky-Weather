--[[ ~/.lua/scripts/weather.lua
      analogue barometer
 2011-05-27 original from Tim CowChip @ http://forum.salixos.org/viewtopic.php?p=26545
 2015-06-21 edited by Alex Kemp

A good Conky/Lua HowTo:-
http://crunchbang.org/forums/viewtopic.php?id=17246
]]

require 'cairo'
require 'imlib2'

static=0 --value for barometer static pointer
update=nil

--update=tonumber(conky_parse('${updates}'))
--if update==1 then print("m1="..m1.."\nm2="..m2) end

--[[ barometer()
 Display an analogue barometer

 @param  cr cairo resource
 @param  pr pressure (mBar or inches Mercury)
 @param  px x centre-position, pixels
 @param  py y centre-position, pixels
 @return (none)
]]
function barometer(cr,pr,px,py)
   --setup table; change barometer appearance
   --htm2col(col,alpha) available for html colour conversion
   local st={
      ctCOL  ={htm2col(0x68441b,1)},     --circle txt colour
      ctFNT  ="URW Chancery L",          --circle txt font name
      ctSize =20,                        --circle txt font size
      ctSLNT =CAIRO_FONT_SLANT_ITALIC,   --circle txt font slant
      ctChang="Change",                  --circle txt 'CHANGE' text
      ctFair ="Fair",                    --circle txt 'FAIR'   text
      ctRain ="Rain",                    --circle txt 'RAIN'   text
      ctStorm="Stormy",                  --circle txt 'STORM'  text
      ctVDry ="Very Dry",                --circle txt 'V DRY'  text
      ctWT   =CAIRO_FONT_WEIGHT_BOLD,    --circle txt font weight
      lw     =5,                         --outer line-width (added to ro)
      ro     =100,                       --radius to outer rim
      bkCOL  ={htm2col(0xf5f5f5,1)},     --background colour
      roCOL  ={htm2col(0x31200d,1)},     --outer rim  colour
      pbCOL  ={0,0,0,0},                 --ptr back   colour
      pfCOL  ={1,0,0,1},                 --ptr fore   colour
      ppCOL  ={0,0,0,1},                 --ptr pivot  colour
      psCOL  ={htm2col(0x68441b,1)},     --ptr static colour
      --psCOL  ={htm2col(0xcdc674,1)},     --ptr static colour
      text   ="Pressure",                --text       text
      txCOL  ={0,0,0,1},                 --text       colour
   }
--[[ barometer 27 inches to 32 inches = 5 inches
              940 Mbar to 1060 millibar 
 'ro*<some-number:0,1>' appears regularly below
 all calcs are based on original radius=100px
 they allow the barometer to be re-sized (within limits)
 eg 'ro*0.75'==a ring at 75 pixels based on orig 100px radius

 circle-text: 87px
     pointer:  7px inner, 75px outer
Pressure txt: 90px
              text : rad outer  : radius inner
  inch scale: 77px : 75,70,68px : 65px
 mbar scale:  37px : 60px       : 55,50px

 line basics: cairo_set_line_cap(cr,CAIRO_LINE_CAP_BUTT) default
              cairo_set_line_cap(cr,CAIRO_LINE_CAP_ROUND)
              cairo_set_line_cap(cr,CAIRO_LINE_CAP_SQUARE)

  arc basics: cairo_arc(cr,centre_x,centre_y,radius,start_angle,end_angle)
              angles are in radians 
              centre + radius are in pixels
              radians=degrees*(math.pi/180)
              0 radians = East (RHS)
                        = 2*math.pi (360 degrees)
]]
   --draw outer rim; fill + stroke
   local lw =st.lw       or 1   -- line-width of outer rim
   local ro =st.ro       or 100 -- radius     of outer rim
   local r  =st.bkCOL[1] or 0.1 -- red   component of background colour
   local g  =st.bkCOL[2] or 0.1 -- green component of background colour
   local b  =st.bkCOL[3] or 0.1 -- blue  component of background colour
   local a  =st.bkCOL[4] or 1   -- alpha component of background colour
   local ARC=2*math.pi          -- 360 degrees
   local D2R=math.pi/180        -- degrees to radians conversion ratio
   cairo_set_line_width(cr,lw)
   cairo_set_source_rgba(cr,r,g,b,a)
   cairo_arc(cr,px,py,ro+lw,0,ARC)
   cairo_fill (cr)
   local r =st.roCOL[1] or 1 -- red   component of outer rim  colour
   local g =st.roCOL[2] or 1 -- green component of outer rim  colour
   local b =st.roCOL[3] or 1 -- blue  component of outer rim  colour
   local a =st.roCOL[4] or 1 -- alpha component of outer rim  colour
   cairo_set_source_rgba(cr,r,g,b,a)
   cairo_arc(cr,px,py,ro+lw,0,ARC)
   cairo_stroke(cr)
   --draw inch + mbar scales
   local r =st.txCOL[1] or 1 -- red   component of text colour
   local g =st.txCOL[2] or 1 -- green component of text colour
   local b =st.txCOL[3] or 1 -- blue  component of text colour
   local a =st.txCOL[4] or 1 -- alpha component of text colour
   --draw inch scale; rout==outer radius; rin==inner radius
   local rout1=ro*0.75
   local rin1=rout1-(ro*0.10)
   for i=0,40 do
      if i==5 or i==15 or i==25 or i==35 then
         rout=rout1-(ro*0.07)
         cairo_set_source_rgba(cr,r,g,b,a)
         cairo_set_line_width(cr,3)
      elseif i==0 or i==10 or i==20 or i==30 or i==40 then
         rout=rout1
         cairo_set_line_width(cr,1)
      else
         rout=rout1-(ro*0.05)
         cairo_set_line_width(cr,1)
      end
      arc=D2R*(210+(i*(300/40)))
      ppx=0+rout*(math.sin(arc))
      ppy=0-rout*(math.cos(arc))
      arc=D2R*(210+(i*300/40))
      pix=0+rin1*(math.sin(arc))
      piy=0-rin1*(math.cos(arc))
      cairo_move_to(cr,px+ppx,py+ppy)
      cairo_line_to(cr,px+pix,py+piy)
      cairo_stroke(cr)
   end
   --draw inch text
   inch={28,29,30,31}
   local rout=rout1+2
   for i=1,4 do
      arc=D2R*(210+(300/8)+((i-1)*(300/4)))
      ppx=0+rout*(math.sin(arc))
      ppy=0-rout*(math.cos(arc))
      text=inch[i]
      extents=cairo_text_extents_t:create()
      cairo_text_extents(cr,text,extents)
      width=extents.width
      height=extents.height
      cairo_move_to(cr,px+ppx-(width/2),py+ppy+(height/2))
      cairo_show_text(cr,text)
      cairo_stroke(cr)
   end
   --942 to 1056
   --27.5=931.25
   --31.5=1066.70
   --draw mbar scale; rout==outer radius; rin==inner radius
   cairo_set_line_width(cr,1)
   local m1=300/135.45
   local m2=m1*8.75--931.25+8.75=940
   local rout2=(ro*0.60)
   local rin2=rout2-(ro*0.05)
   local num=60
   for i=0,num do
      if i==0 or i==5 or i==10 or i==15 or i==20 or i==25 or i==30 or i==35 or i==40 or i==45 or i==50 or i==55 or i==60 or i==65 then
         rin=rin2-(ro*0.05)
      else
         rin=rin2
      end
--    arc=D2R*(210+m2+(i*((m1*(num*2))/num)))
      arc=D2R*(210+m2+(i*m1*2))
      ppx=0+rout2*(math.sin(arc))
      ppy=0-rout2*(math.cos(arc))
      pix=0+rin*(math.sin(arc))
      piy=0-rin*(math.cos(arc))
      cairo_move_to (cr,px+ppx,py+ppy)
      cairo_line_to (cr,px+pix,py+piy)
      cairo_stroke (cr)
   end
   --draw mbar text
   inch={940,960,980,1000,1020,1040,1060}
   local rout=rin2-(ro*0.18)
   local maxW=0
   for i=1,7 do
      arc=D2R*(210+m2+((i-1)*(m1*20)))
      ppx=0+rout*(math.sin(arc))
      ppy=0-rout*(math.cos(arc))
      text=inch[i]
      extents=cairo_text_extents_t:create()
      cairo_text_extents(cr,text,extents)
      width=extents.width
      height=extents.height
      if  width>maxW  then maxW=width  end
      cairo_move_to(cr,px+ppx-(width/2),py+ppy+(height/2))
      cairo_show_text(cr,text)
      cairo_stroke(cr)
   end
   --scale labels
   local text="inches hg"
   local extents=cairo_text_extents_t:create()
   cairo_text_extents(cr,text,extents)
   local width=extents.width
   local height=extents.height
   cairo_move_to(cr,px-(width/2),py+rin1)
   cairo_show_text(cr,text)
   cairo_stroke(cr)
   local text="millibars"
   extents=cairo_text_extents_t:create()
   cairo_text_extents(cr,text,extents)
   local width=extents.width
   local height=extents.height
   cairo_move_to(cr,px-(width/2),py+rin2-height)
   cairo_show_text(cr,text)
   cairo_stroke(cr)
   local text=st.text or "Pressure";
   extents=cairo_text_extents_t:create()
   cairo_text_extents(cr,text,extents)
   local width=extents.width
   local height=extents.height
   cairo_move_to(cr,px-(width/2),py+rin2+(ro*0.35))
   cairo_show_text(cr,text)
   cairo_stroke(cr)
--[[ draw pointer
  psx,psy static  tip,  rout1 radius
  ptx,pty pointer tip,  rout1 radius
  pbx,pby pointer base, rout  radius w/adjust for inner text width
  pex,pey pb end cap,   rout  radius

  static pointer has value set at first value of pressure>0

  expects pressure in inches Hg
  1 inch Hg == 33.8638866667 mBar
]]
   pr=tonumber(pr)
   local pres=1
   if pr<1 then pr=27.5 end--account for zero value
   if pr>500  then
      -- it's in mBar; convert to inches
      pres=(pr/33.8638867) - 27.5
   else
      -- it's in inches, or we're all dead
      pres=pr-27.5
   end
   if static<1 and pres>0 then
      --static pointer value
      static=pres
   end
   local m1=300/4            -- top part of ptr
   local m2=pres*m1
   local arc=D2R*(210+m2)
   local sin=math.sin(arc)
   local cos=math.cos(arc)
   local ptx=px+rout1*sin
   local pty=py-rout1*cos
   ------------------------------
   arc=D2R*(210+m2+180)      -- bottom part of ptr
   sin=math.sin(arc)
   cos=math.cos(arc)
   local pbx=px+((rout-maxW)*sin)
   local pby=py-((rout-maxW)*cos)
   local pex=px+((rout-(2*maxW/3))*sin)
   local pey=py-((rout-(2*maxW/3))*cos)
   --------------------------------
   local psx,psy,arb         -- static ptr
   if ((static<1) or (static==pres)) then
      psx,psy=ptx,pty
   else
      m2=static*m1
      arb=D2R*(210+m2)
      sin=math.sin(arb)
      cos=math.cos(arb)
      psx=px+rout1*sin
      psy=py-rout1*cos
   end
   --------------------------------
   local r =st.pfCOL[1] or 0 -- red   component of ptr fore   colour
   local g =st.pfCOL[2] or 0 -- green component of ptr fore   colour
   local b =st.pfCOL[3] or 0 -- blue  component of ptr fore   colour
   local a =st.pfCOL[4] or 1 -- alpha component of ptr fore   colour
   cairo_set_source_rgba(cr,r,g,b,a)
   cairo_set_line_width(cr,3)
   cairo_set_line_cap(cr,CAIRO_LINE_CAP_ROUND)
   cairo_arc(cr,pex,pey,maxW/3,arc,arc-math.pi)
   cairo_move_to(cr,ptx,pty)
   cairo_line_to(cr,pbx,pby)
   cairo_move_to(cr,px,py)
   cairo_arc(cr,px,py,ro*0.04,0,ARC)
   cairo_stroke(cr)
   --------------------------------
   local r  =st.bkCOL[1] or 0.1 -- red   component of background colour
   local g  =st.bkCOL[2] or 0.1 -- green component of background colour
   local b  =st.bkCOL[3] or 0.1 -- blue  component of background colour
   local a  =st.bkCOL[4] or 1   -- alpha component of background colour
   cairo_set_source_rgba(cr,r,g,b,a)
   cairo_arc(cr,px,py,ro*0.02,0,ARC)
   --cairo_arc(cr,px,py,ro*0.03,0,ARC)
   cairo_fill(cr)
   --------------------------------
   local r  =st.psCOL[1] or 0   -- red   component of static ptr colour
   local g  =st.psCOL[2] or 0   -- green component of static ptr colour
   local b  =st.psCOL[3] or 0   -- blue  component of static ptr colour
   local a  =st.psCOL[4] or 1   -- alpha component of static ptr colour
   cairo_set_source_rgba(cr,r,g,b,a)
   cairo_set_line_width(cr,1)
   cairo_move_to(cr,psx,psy)
   cairo_line_to(cr,px,py)
   cairo_stroke(cr)
   cairo_arc(cr,px,py,ro*0.02,0,ARC)
   --cairo_arc(cr,px,py,ro*0.04,0,ARC)
   cairo_fill(cr)
--[[ original pointer
-- begin speedo-type pointer (alpha=0 - no bottom part of pointer)
--    or magnet-type pointer (alpha=1 for top&bottom)
   local m1=300/4
   local m2=pres*m1
   local rout1=rout1
   local arc=D2R*(210+m2)
   local ppx=0+rout1*(math.sin(arc))
   local ppy=0-rout1*(math.cos(arc))
   ------------------------------
   local arc=D2R*(210+m2+180)
   local ppox=0+rout1*(math.sin(arc))
   local ppoy=0-rout1*(math.cos(arc))
   -------------------------------
   local rin3=(ro*0.07)
   local arc=D2R*(210+m2-90)
   local pilx=0+rin3*(math.sin(arc))
   local pily=0-rin3*(math.cos(arc))
   local arc=D2R*(210+m2+90)
   local pirx=0+rin3*(math.sin(arc))
   local piry=0-rin3*(math.cos(arc))
   --------------------------------
   local r =st.pfCOL[1] or 1 -- red   component of ptr fore   colour
   local g =st.pfCOL[2] or 0 -- green component of ptr fore   colour
   local b =st.pfCOL[3] or 0 -- blue  component of ptr fore   colour
   local a =st.pfCOL[4] or 1 -- alpha component of ptr fore   colour
   cairo_move_to(cr,px+pilx,py+pily)
   cairo_line_to(cr,px+ppx,py+ppy)
   cairo_line_to(cr,px+pirx,py+piry)
   cairo_line_to(cr,px+pilx,py+pily)
   cairo_set_source_rgba(cr,r,g,b,a)
   cairo_fill(cr)
   cairo_arc(cr,px,py,rin3,0,ARC)
   cairo_fill(cr)
   ---------------------------------
   local r =st.pbCOL[1] or 1 -- red   component of ptr back   colour
   local g =st.pbCOL[2] or 1 -- green component of ptr back   colour
   local b =st.pbCOL[3] or 1 -- blue  component of ptr back   colour
   local a =st.pbCOL[4] or 1 -- alpha component of ptr back   colour
   cairo_move_to (cr,px+pilx,py+pily)
   cairo_line_to (cr,px+ppox,py+ppoy)
   cairo_line_to (cr,px+pirx,py+piry)
   cairo_line_to (cr,px+pilx,py+pily)
   cairo_set_source_rgba (cr,r,b,g,a)
   cairo_fill (cr)
   local r =st.pfCOL[1] or 1 -- red   component of ptr fore   colour
   local g =st.pfCOL[2] or 0 -- green component of ptr fore   colour
   local b =st.pfCOL[3] or 0 -- blue  component of ptr fore   colour
   local a =st.pfCOL[4] or 1 -- alpha component of ptr fore   colour
   cairo_set_source_rgba (cr,r,g,b,a)
   cairo_arc (cr,px,py,rin3,0,ARC)
   cairo_fill (cr)
   -----------------------------------
   local r =st.ppCOL[1] or 0 -- red   component of ptr pivot  colour
   local g =st.ppCOL[2] or 0 -- green component of ptr pivot  colour
   local b =st.ppCOL[3] or 0 -- blue  component of ptr pivot  colour
   local a =st.ppCOL[4] or 1 -- alpha component of ptr pivot  colour
   cairo_set_source_rgba (cr,r,g,b,a)
   cairo_arc (cr,px,py,rin3-1,0,ARC)
   cairo_fill (cr)
-- end   car   -type pointer (alpha=0 so no bottom part of pointer) ]]
   ----circle text
   local horiz=px
   local verti=py
   local radi=(ro*0.87)
   local font=st.ctFNT   or "Mono";
   local text=st.ctStorm or "STORMY";
   local size=st.ctSize  or 12;
   local fsize=(ro*size/100)
   local start=250
   local finish=start+((string.len(text))*5)
   circlewriting(cr, text, font, fsize, radi, horiz, verti, start, finish,st)
   local text=st.ctRain  or "RAIN";
   local start=300
   local finish=start+((string.len(text))*5)
   circlewriting(cr, text, font, fsize, radi, horiz, verti, start, finish,st)
   local text=st.ctChang or "CHANGE";
   local start=340
   local finish=start+((string.len(text))*5)
   circlewriting(cr, text, font, fsize, radi, horiz, verti, start, finish,st)
   local text=st.ctFair  or "FAIR";
   local start=395
   local finish=start+((string.len(text))*5)
   circlewriting(cr, text, font, fsize, radi, horiz, verti, start, finish,st)
   local text=st.ctVDry  or "VERY DRY";
   local start=435
   local finish=start+((string.len(text))*5)
   circlewriting(cr, text, font, fsize, radi, horiz, verti, start, finish,st)
end-- function barometer

------------------------------------------------------------------------------
function circlewriting(cr, text, font, fsize, radi, horiz, verti, start, finish, st)
   local r =st.ctCOL[1] or 1 -- red   component of circle txt colour
   local g =st.ctCOL[2] or 1 -- green component of circle txt colour
   local b =st.ctCOL[3] or 1 -- blue  component of circle txt colour
   local a =st.ctCOL[4] or 1 -- alpha component of circle txt colour
   local s =st.ctSLNT   or CAIRO_FONT_SLANT_NORMAL  -- font slant  setting
   local w =st.ctWT     or CAIRO_FONT_WEIGHT_NORMAL -- font weight setting
    cairo_select_font_face (cr, font, s, w);
    cairo_set_font_size (cr, fsize)
    cairo_set_source_rgba (cr,r,g,b,a);
    local inum=string.len(text)
    local deg=(finish-start)/(inum-1)
    local degrads=(math.pi/180)
    local textcut=string.gsub(text, ".", "%1|")
    texttable=string.split(textcut, "|")
    for i=1,inum do
    interval=(degrads*(start+(deg*(i-1))))
    txs=0+radi*(math.sin(interval))
    tys=0-radi*(math.cos(interval))
    cairo_move_to (cr, txs+horiz, tys+verti);
    cairo_rotate (cr, interval)
    cairo_show_text (cr, (texttable[i]))
    cairo_stroke (cr)
    cairo_rotate (cr, -interval)
    end
end--function circlewriting

    ------------------------------------------------------------------------------
    function string:split(delimiter)
    local result = { }
    local from  = 1
    local delim_from, delim_to = string.find( self, delimiter, from  )
    while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
    end
    table.insert( result, string.sub( self, from  ) )
    return result
    end
    --------------------------------------------------------------------------------
    function wspeed_dial(ws,px,py)
    --0 to 60 mph
    --draw circle
    cairo_set_line_width (cr,1)
    local router=110
    cairo_set_source_rgba (cr,0.1,0.1,0.1,1)
    cairo_arc (cr,px,py,router,0,(2*math.pi))
    cairo_fill (cr)
    cairo_set_source_rgba (cr,1,1,1,1)
    cairo_arc (cr,px,py,router,0,(2*math.pi))
    cairo_stroke (cr)
    -------------------------------------------
    --mph scale
    local rout1=80
    local rin1=rout1-10
    for i=0,60 do
    if i==5 or i==15 or i==25 or i==35 or i==45 then
    rin=rin1--set line length for 5s
    cairo_set_line_width (cr,1)
    elseif i==0 or i==10 or i==20 or i==30 or i==40 or i==50 or i==60 then
    rin=rin1+7--set line length for 10's
    cairo_set_line_width (cr,3)
    else
    rin=rin1+5--set other lines
    cairo_set_line_width (cr,1)
    end--if i==
    arc=(math.pi/180)*(210+(i*(300/60)))
    ppx=0+rout1*(math.sin(arc))
    ppy=0-rout1*(math.cos(arc))
    arc=(math.pi/180)*(210+(i*300/60))
    pix=0+rin*(math.sin(arc))
    piy=0-rin*(math.cos(arc))
    cairo_move_to (cr,px+ppx,py+ppy)
    cairo_line_to (cr,px+pix,py+piy)
    cairo_stroke (cr)
    end--for i=
    --mph reading
    mph={0,10,20,30,40,50,60}
    local rin=rin1-2
    for i=1,#mph do
    arc=(math.pi/180)*(210+((i-1)*(300/6)))
    ppx=0+rin*(math.sin(arc))
    ppy=0-rin*(math.cos(arc))
    text=mph[i]
    extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    width=extents.width
    height=extents.height
    cairo_move_to (cr,px+ppx-(width/2),py+ppy+(height/2))
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    end--for i= print inches
    --kmh lines and numbers
    --60kmh=96.5606
    cairo_set_line_width (cr,1)
    local m1=300/96.5606
    local rout2=60
    local rin2=rout2-5
    local num=95
    --print lines---------------
    for i=0,num do
    if i==0 or i==10 or i==20 or i==30 or i==40 or i==50 or i==60 or i==70 or i==80 or i==90 then
    rin=rin2-5--set length for 10s
    elseif i==5 or i==15 or i==25 or i==35 or i==45 or i==55 or i==65 or 1==75 or i==85 or i==95 then
    rin=rin2-2--set length for 5's
    else
    rin=rin2
    end--if i=
    ---------------------------------------------------
    arc=(math.pi/180)*(210+(i*m1))
    ppx=0+rout2*(math.sin(arc))
    ppy=0-rout2*(math.cos(arc))
    arc=(math.pi/180)*(210+(i*m1))
    pix=0+rin*(math.sin(arc))
    piy=0-rin*(math.cos(arc))
    cairo_move_to (cr,px+ppx,py+ppy)
    cairo_line_to (cr,px+pix,py+piy)
    cairo_stroke (cr)
    end--for i --line drawing
    --kmh reading
    kmh={0,10,20,30,40,50,60,70,80,90}
    local rout=rin2-18
    for i=1,#kmh do
    arc=(math.pi/180)*(210+((i-1)*(m1*10)))
    ppx=0+rout*(math.sin(arc))
    ppy=0-rout*(math.cos(arc))
    text=kmh[i]
    extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    width=extents.width
    height=extents.height
    cairo_move_to (cr,px+ppx-(width/2),py+ppy+(height/2))
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    end--kmh lines and numbers
    --knots
    --60kmh=52.1386
    cairo_set_line_width (cr,1)
    local m1=300/52.1386
    local rout3=90
    local rin3=rout3-5
    local num=50
    --print lines---------------
    for i=0,num do
    if i==0 or i==10 or i==20 or i==30 or i==40 or i==50 then
    rout=rout3-1--set length for 10s
    cairo_set_line_width (cr,3)
    elseif i==5 or i==15 or i==25 or i==35 or i==45 then
    rout=rout3+4--set length for 5's
    cairo_set_line_width (cr,1)
    else
    rout=rout3
    cairo_set_line_width (cr,1)
    end--if i=
    ---------------------------------------------------
    arc=(math.pi/180)*(210+(i*m1))
    ppx=0+rout*(math.sin(arc))
    ppy=0-rout*(math.cos(arc))
    arc=(math.pi/180)*(210+(i*m1))
    pix=0+rin3*(math.sin(arc))
    piy=0-rin3*(math.cos(arc))
    cairo_move_to (cr,px+pix,py+piy)
    cairo_line_to (cr,px+ppx,py+ppy)
    cairo_stroke (cr)
    end--for i --line drawing
    --kmh reading
    knot={0,10,20,30,40,50}
    local rout=rin3+15
    for i=1,#kmh do
    arc=(math.pi/180)*(210+((i-1)*(m1*10)))
    ppx=0+rout*(math.sin(arc))
    ppy=0-rout*(math.cos(arc))
    text=knot[i]
    extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    width=extents.width
    height=extents.height
    cairo_move_to (cr,px+ppx-(width/2),py+ppy+(height/2))
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    end
    --scale labels
    local text="mph"
    local extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    local width=extents.width
    local height=extents.height
    cairo_move_to (cr,px-(width/2),py+rin1)
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    local text="kmh"
    extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    local width=extents.width
    local height=extents.height
    cairo_move_to (cr,px-(width/2),py+rin2)
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    local text="knots"
    extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    local width=extents.width
    local height=extents.height
    cairo_move_to (cr,px-(width/2),py+rin3)
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    local text="Wind Speed"
    extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    local width=extents.width
    local height=extents.height
    cairo_move_to (cr,px-(width/2),py+rin3+16)
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    --pointer
    if ws==nil then ws=0 end
    local wspd=ws
    local m1=300/60
    local m2=wspd*m1
    local rout1=rout3
    local arc=(math.pi/180)*(210+m2)
    local ppx=0+rout1*(math.sin(arc))
    local ppy=0-rout1*(math.cos(arc))
    ------------------------------
    local arc=(math.pi/180)*(210+m2+180)
    local ppox=0+rout1*(math.sin(arc))
    local ppoy=0-rout1*(math.cos(arc))
    -------------------------------
    local rin3=7
    local arc=(math.pi/180)*(210+m2-90)
    local pilx=0+rin3*(math.sin(arc))
    local pily=0-rin3*(math.cos(arc))
    local arc=(math.pi/180)*(210+m2+90)
    local pirx=0+rin3*(math.sin(arc))
    local piry=0-rin3*(math.cos(arc))
    --------------------------------
    cairo_move_to (cr,px+pilx,py+pily)
    cairo_line_to (cr,px+ppx,py+ppy)
    cairo_line_to (cr,px+pirx,py+piry)
    cairo_line_to (cr,px+pilx,py+pily)
    cairo_set_source_rgba (cr,1,0,0,1)
    cairo_fill (cr)
    cairo_arc (cr,px,py,rin3,0,(2*math.pi))
    cairo_fill (cr)
    ---------------------------------
    cairo_move_to (cr,px+pilx,py+pily)
    cairo_line_to (cr,px+ppox,py+ppoy)
    cairo_line_to (cr,px+pirx,py+piry)
    cairo_line_to (cr,px+pilx,py+pily)
    cairo_set_source_rgba (cr,1,1,1,1)
    cairo_fill (cr)
    cairo_set_source_rgba (cr,1,0,0,1)
    cairo_arc (cr,px,py,rin3,0,(2*math.pi))
    cairo_fill (cr)
    -----------------------------------
    cairo_set_source_rgba (cr,0,0,0,1)
    cairo_arc (cr,px,py,rin3-1,0,(2*math.pi))
    cairo_fill (cr)
    end--wspeed dial function
    ------------------------------------------------------------------------------
    function humidity(x,y,hval1)
    hval=hval1*1.5
    yt=y-1
    rh=151
    rw=30
    local pat = cairo_pattern_create_linear (0,yt,0,yt+rh);
    cairo_pattern_add_color_stop_rgba (pat, 1, 0, 0, 1, 0);
    cairo_pattern_add_color_stop_rgba (pat, 0, 0, 0, 1, 1);
    cairo_rectangle (cr,x,yt,rw, rh);
    cairo_set_source (cr, pat);
    cairo_fill (cr);
    cairo_pattern_destroy (pat);
    ----------
    for i=1,11 do
    lwid=-1
    cairo_set_source_rgba (cr,1,1,1,1)
    cairo_move_to (cr,x+rw,(y+150)-((i-1)*15))
    cairo_rel_line_to (cr,lwid,0)
    cairo_stroke(cr)
    end
    ----------
    cairo_set_source_rgba (cr,1,1,1,1)
    hh=5
    hw1=19
    hw2=hw1+10
    if hval==nil then hval=0 end
    tx,ty=x+hw1,(y+150)-(hval+hh)
    ix,iy=x+hw2,(y+150)-hval
    bx,by=x+hw1,(y+150)-(hval-hh)
    cairo_move_to (cr,tx,ty)
    cairo_line_to (cr,ix,iy)
    cairo_line_to (cr,bx,by)
    cairo_line_to (cr,tx,ty)
    cairo_fill (cr)
    cairo_set_source_rgba (cr,1,1,1,1)
    font="Mono"
    fsize=12
    cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size (cr, fsize)
    cairo_move_to (cr,x+hw2+3,(y+150)-(hval-hh))
    cairo_show_text (cr,hval1.."%")
    cairo_stroke (cr)
    label="Relative Humidity"
    cairo_move_to (cr,x+12,y+150)
    cairo_rotate (cr,(math.pi/180)*(-90))
    cairo_show_text (cr,label)
    cairo_stroke (cr)
    cairo_rotate (cr,(math.pi/180)*(90))
    end--humidity
    ------------------------------------------------------------------------------
    function txt(text,xpos,ypos,font,fsize,red,green,blue,alpha)
    cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size (cr, fsize)
    cairo_set_source_rgba (cr,red,green,blue,alpha)
    cairo_move_to (cr,xpos,ypos)
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    end--function txt
    ------------------------------------------------------------------------------
    function compass(wx,wy,rout,wdeg,w,wg)
    local rin=rout-((rout/100)*10)
    cairo_set_source_rgba (cr,0.1,0.1,0.1,1)
    cairo_arc (cr,wx,wy,rout,0,(2*math.pi))
    cairo_fill (cr)
    cairo_set_source_rgba (cr,1,1,1,1)
    cairo_arc (cr,wx,wy,rout,0,(2*math.pi))
    cairo_stroke (cr)
    for i=1,36 do
    arc=(math.pi/180)*(i*10)
    wpx=0+rout*(math.sin(arc))
    wpy=0-rout*(math.cos(arc))
    arc=(math.pi/180)*(i*10)
    wix=0+rin*(math.sin(arc))
    wiy=0-rin*(math.cos(arc))
    cairo_move_to (cr,wx+wpx,wy+wpy)
    cairo_line_to (cr,wx+wix,wy+wiy)
    cairo_stroke (cr)
    end
    --print directions
    local font="Mono"
    local fsize=10
    cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size (cr, fsize)
    dirs={"N","NE","E","SE","S","SW","W","NW"}
    local rdir=rout-((rout/100)*25)
    for i=1,8 do
    arc=(math.pi/180)*((i-1)*(360/8))
    wdx=0+rdir*(math.sin(arc))
    wdy=0-rdir*(math.cos(arc))
    text=dirs[i]
    extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    width=extents.width
    height=extents.height
    cairo_move_to (cr,wx+wdx-(width/2),wy+wdy+(height/2))
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    end
    --indicator
    local npr=rout-((rout/100)*15)
    if wdeg==nil then wdeg=0 end
    local arc=(math.pi/180)*(wdeg)
    local npx=0+npr*(math.sin(arc))
    local npy=0-npr*(math.cos(arc))
    cairo_move_to (cr,wx+npx,wy+npy)
    local nprm=rout-((rout/100)*88)
    local arc=(math.pi/180)*(wdeg+90)
    local npmrx=0+nprm*(math.sin(arc))
    local npmry=0-nprm*(math.cos(arc))
    local arc=(math.pi/180)*(wdeg-90)
    local npmlx=0+nprm*(math.sin(arc))
    local npmly=0-nprm*(math.cos(arc))
    cairo_line_to (cr,wx+npmrx,wy+npmry)
    cairo_line_to (cr,wx+npmlx,wy+npmly)
    cairo_line_to (cr,wx+npx,wy+npy)
    cairo_set_source_rgba (cr,1,0,0,1)
    cairo_fill (cr)
    cairo_set_source_rgba (cr,1,1,1,1)
    ---------------------------------
    local arc=(math.pi/180)*(wdeg-180)
    local spx=0+npr*(math.sin(arc))
    local spy=0-npr*(math.cos(arc))
    cairo_move_to (cr,wx+spx,wy+spy)
    local sprm=nprm
    local arc=(math.pi/180)*(wdeg+90-180)
    local spmrx=0+sprm*(math.sin(arc))
    local spmry=0-sprm*(math.cos(arc))
    local arc=(math.pi/180)*(wdeg-90-180)
    local spmlx=0+sprm*(math.sin(arc))
    local spmly=0-sprm*(math.cos(arc))
    cairo_line_to (cr,wx+spmrx,wy+spmry)
    cairo_line_to (cr,wx+spmlx,wy+spmly)
    cairo_line_to (cr,wx+spx,wy+spy)
    cairo_fill (cr)
    --------------------------------------
    cairo_set_source_rgba (cr,0,0,0,1)
    cairo_arc (cr,wx,wy,nprm,0,(2*math.pi))
    cairo_fill (cr)
    cairo_set_source_rgba (cr,1,0,0,1)
    cairo_arc (cr,wx,wy,nprm,0,(2*math.pi))
    cairo_stroke (cr)
    ------------------------
    cairo_set_source_rgba (cr,1,1,1,1)
    local text="Wind Direction"
    local extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    local width=extents.width
    local height=extents.height
    cairo_move_to (cr,wx-(width/2),wy-rout-5)
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    end--compass
    ------------------------------------------------------------------------------
    function thermometer(mx,my,temp,label,scale,mid,units)
    --by mrpeachy 2011
    if scale==nil then scale=1 end
    if units=="F" then height=150 elseif units=="C" then height=160 end
    local mx=mx*(1/scale)
    local my=my*(1/scale)
    local font="Mono"
    local fsize=10
    cairo_scale (cr,scale,scale)
    cairo_set_line_width (cr,1)
    cairo_set_source_rgba (cr,1,1,1,1)
    --graphics outer
    --bottom circle
    r_outer=25
    local lang_outer=335
    local rang_outer=0+(360-lang_outer)
    local h_outer=height-4--maybe make this a percentage?###########
    cairo_arc (cr,mx,my,r_outer,(math.pi/180)*(rang_outer-90),(math.pi/180)*(lang_outer-90))
    --coordinates,left line
    local arc=(math.pi/180)*lang_outer
    local lxo=0+r_outer*(math.sin(arc))
    local lyo=0-r_outer*(math.cos(arc))
    cairo_line_to (cr,mx+lxo,my+lyo-h_outer)
    --coordinates,left line
    local arc=(math.pi/180)*rang_outer
    local rxo=0+r_outer*(math.sin(arc))
    local ryo=0-r_outer*(math.cos(arc))
    --top circle
    cairo_arc (cr,mx+lxo+((rxo-lxo)/2),my+lyo-h_outer,(rxo-lxo)/2,(math.pi/180)*(270-90),(math.pi/180)*(90-90))
    --right line
    cairo_line_to (cr,mx+lxo+((rxo-lxo)),my+lyo)
    cairo_stroke (cr)
    ----------------------------------------------
    --graphics inner
    --####################################################
    if units=="F" then
    local str,stg,stb,sta=0,1,1,1
    local mr,mg,mb,ma=1,1,0,1
    local fr,fg,fb,fa=1,0,0,1
    local nd=150
    if temp==nil then temp=0 end
    local tadj=temp+30
    local middle=mid+30
    if tadj<(middle) then
    colr=((mr-str)*(tadj/(middle)))+str
    colg=((mg-stg)*(tadj/(middle)))+stg
    colb=((mb-stb)*(tadj/(middle)))+stb
    cola=((ma-sta)*(tadj/(middle)))+sta
    elseif tadj>=(middle) then
    colr=((fr-mr)*((tadj-(middle))/(nd-middle)))+mr
    colg=((fg-mg)*((tadj-(middle))/(nd-middle)))+mg
    colb=((fb-mb)*((tadj-(middle))/(nd-middle)))+mb
    cola=((fa-ma)*((tadj-(middle))/(nd-middle)))+ma
    end
    cairo_set_source_rgba (cr,colr,colg,colb,cola)
    --bottom circle
    r_inner=r_outer-6
    local lang_inner=lang_outer+9
    local rang_inner=0+(360-lang_inner)
    local h_inner=temp+30
    cairo_arc (cr,mx,my,r_inner,(math.pi/180)*(rang_inner-90),(math.pi/180)*(lang_inner-90))
    --coordinates,left line
    local arc=(math.pi/180)*lang_inner
    lxi=0+r_inner*(math.sin(arc))
    local lyi=0-r_inner*(math.cos(arc))
    cairo_line_to (cr,mx+lxi,my+lyi-h_inner)
    --coordinates,left line
    local arc=(math.pi/180)*rang_inner
    rxi=0+r_inner*(math.sin(arc))
    local ryi=0-r_inner*(math.cos(arc))
    --top circle
    cairo_arc (cr,mx+lxi+((rxi-lxi)/2),my+lyi-h_inner,(rxi-lxi)/2,(math.pi/180)*(270-90),(math.pi/180)*(90-90))
    --right line
    cairo_line_to (cr,mx+lxi+((rxi-lxi)),my+lyi)
    cairo_fill (cr)
    ----------------------------
    if label~="none" then
    --scale lines
    cairo_set_line_width (cr,1)
    cairo_set_source_rgba (cr,1,1,1,0.5)
    local grad=10
    local lnn=15
    local lnx=mx+lxo
    local lnw=(rxo-lxo)
    for i=1,lnn do
    lny=my-r_inner-(10+((i-1)*grad))-((rxi-lxi)/2)
    if i==lnn then
    lnx=lnx+2
    lnw=lnw-4
    end
    cairo_move_to (cr,lnx,lny)
    cairo_rel_line_to (cr,lnw,0)
    cairo_stroke (cr)
    end
    --numbers
    cairo_set_source_rgba (cr,1,1,1,1)
    cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size (cr, fsize)
    local grad=20
    local lnn=8
    local lnx=mx+lxo+(rxo-lxo)+4
    num={-20,"0°"..units,20,40,60,80,100,120}
    for i=1,lnn do
    lny=my-r_inner-(10+((i-1)*grad))-((rxi-lxi)/2)+(fsize/3)
    cairo_move_to (cr,lnx,lny)
    cairo_show_text (cr,num[i])
    cairo_stroke (cr)
    end
    end--if label=none
    end--if units=F
    --#################################################
    if units=="C" then
    --from -30 to 50 C
    local str,stg,stb,sta=0,1,1,1
    local mr,mg,mb,ma=1,1,0,1
    local fr,fg,fb,fa=1,0,0,1
    local nd=160
    if temp==nil then temp=0 end
    local tadj=(temp*2)+60
    local middle=(mid*2)+60
    if tadj<(middle) then
    colr=((mr-str)*(tadj/(middle)))+str
    colg=((mg-stg)*(tadj/(middle)))+stg
    colb=((mb-stb)*(tadj/(middle)))+stb
    cola=((ma-sta)*(tadj/(middle)))+sta
    elseif tadj>=(120) then
    colr=((fr-mr)*((tadj-(middle))/(nd-middle)))+mr
    colg=((fg-mg)*((tadj-(middle))/(nd-middle)))+mg
    colb=((fb-mb)*((tadj-(middle))/(nd-middle)))+mb
    cola=((fa-ma)*((tadj-(middle))/(nd-middle)))+ma
    end
    cairo_set_source_rgba (cr,colr,colg,colb,cola)
    --cairo_set_source_rgba (cr,0,1,1,1)
    --bottom circle
    r_inner=r_outer-6
    local lang_inner=lang_outer+9
    local rang_inner=0+(360-lang_inner)
    local h_inner=(temp*2)+60
    cairo_arc (cr,mx,my,r_inner,(math.pi/180)*(rang_inner-90),(math.pi/180)*(lang_inner-90))
    --coordinates,left line
    local arc=(math.pi/180)*lang_inner
    lxi=0+r_inner*(math.sin(arc))
    local lyi=0-r_inner*(math.cos(arc))
    cairo_line_to (cr,mx+lxi,my+lyi-h_inner)
    --coordinates,left line
    local arc=(math.pi/180)*rang_inner
    rxi=0+r_inner*(math.sin(arc))
    local ryi=0-r_inner*(math.cos(arc))
    --top circle
    cairo_arc (cr,mx+lxi+((rxi-lxi)/2),my+lyi-h_inner,(rxi-lxi)/2,(math.pi/180)*(270-90),(math.pi/180)*(90-90))
    --right line
    cairo_line_to (cr,mx+lxi+((rxi-lxi)),my+lyi)
    cairo_fill (cr)
    ----------------------------
    if label~="none" then
    --scale lines
    cairo_set_line_width (cr,1)
    cairo_set_source_rgba (cr,1,1,1,0.5)
    local grad=10
    local lnn=17
    local lnx=mx+lxo
    local lnw=(rxo-lxo)
    for i=1,lnn do
    lny=my-r_inner-(((i-1)*grad))-((rxi-lxi)/2)
    if i==lnn then
    lnx=lnx+2
    lnw=lnw-4
    end
    cairo_move_to (cr,lnx,lny)
    cairo_rel_line_to (cr,lnw,0)
    cairo_stroke (cr)
    end
    --numbers
    cairo_set_source_rgba (cr,1,1,1,1)
    cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size (cr, fsize)
    local grad=20
    local lnn=9
    local lnx=mx+lxo+(rxo-lxo)+4
    num={-30,-20,-10,"0°"..units,10,20,30,40,50}
    for i=1,lnn do
    lny=my-r_inner-(((i-1)*grad))-((rxi-lxi)/2)+(fsize/3)
    cairo_move_to (cr,lnx,lny)
    cairo_show_text (cr,num[i])
    cairo_stroke (cr)
    end
    end--if label=none
    end--if units=C
    --#################################################
    --label
    if label~="none" then
    local font="Mono"
    local fsize=12
    cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size (cr, fsize)
    local lbx=mx+lxo-5
    local lby=my-r_inner-10-((rxi-lxi)/2)
    cairo_move_to (cr,lbx,lby)
    cairo_rotate (cr,(math.pi/180)*(-90))
    cairo_show_text (cr,label)
    cairo_stroke (cr)
    cairo_rotate (cr,(math.pi/180)*(90))
    --temperature readout
    cairo_set_source_rgba (cr,0,0,0,1)
    local text=temp.."°"..units
    local extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    local width=extents.width
    local height=extents.height
    cairo_move_to (cr,mx-(width/2),my+(height/2))
    cairo_show_text (cr,text)
    cairo_stroke (cr)
    end--if label
    ------------------------------------
    cairo_scale (cr,1/scale,1/scale)
    end--thermometer function
    ------------------------------------------------------------------------------
    function conky_draw_bg(r,x,y,w,h,color,alpha)
    if conky_window == nil then return end
    if cs == nil then cairo_surface_destroy(cs) end
    if cr == nil then cairo_destroy(cr) end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)
    cairo_set_source_rgba (cr,htm2col(color,alpha))
    --top left mid circle
    local xtl=x+r
    local ytl=y+r
    --top right mid circle
    local xtr=(x+r)+((w)-(2*r))
    local ytr=y+r
    --bottom right mid circle
    local xbr=(x+r)+((w)-(2*r))
    local ybr=(y+r)+((h)-(2*r))
    --bottom right mid circle
    local xbl=(x+r)
    local ybl=(y+r)+((h)-(2*r))
    -----------------------------
    cairo_move_to (cr,xtl,ytl-r)
    cairo_line_to (cr,xtr,ytr-r)
    cairo_arc(cr,xtr,ytr,r,((2*math.pi/4)*3),((2*math.pi/4)*4))
    cairo_line_to (cr,xbr+r,ybr)
    cairo_arc(cr,xbr,ybr,r,((2*math.pi/4)*4),((2*math.pi/4)*1))
    cairo_line_to (cr,xbl,ybl+r)
    cairo_arc(cr,xbl,ybl,r,((2*math.pi/4)*1),((2*math.pi/4)*2))
    cairo_line_to (cr,xtl-r,ytl)
    cairo_arc(cr,xtl,ytl,r,((2*math.pi/4)*2),((2*math.pi/4)*3))
    cairo_close_path(cr)
    cairo_fill (cr)
    -----------------------------
    cairo_surface_destroy(cs)
    cairo_destroy(cr)
    return ""
    end-- conky_draw_bg function

--[[ htm2col()
 Parse a HTML-colour + return lua/cairo-suitable colours.
 This function parses colours like 0xrrggbb + alpha in the range [0, 1]
 For example, htm2col(0x00ff00,1.0) would return 0, 1, 0, 1.
 obtained from clock_rings

 @param colour The colour to parse eg 0xffffff (white)
 @param alpha  The alpha  to parse eg 0.5
 @return 4 values which each are in the range [0, 1].
]]
function htm2col(colour,alpha)
   return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end

 ------------------------------------------------------------------------------
function conky_draw_test()
   if conky_window==nil then return end
   local cs=cairo_xlib_surface_create(conky_window.display,conky_window.drawable,conky_window.visual,conky_window.width,conky_window.height)
   local cr=cairo_create(cs)    
   local pressure=tonumber(conky_parse('${execi 300 /home/alexk/.conky/weather.pl EGNX ALT_HP}'))
-- local pressure=tonumber(conky_parse('${weather http://weather.noaa.gov/pub/data/observations/metar/stations/ EGNX pressure 30}'))

   barometer(cr,pressure,120,150)
   -----------------------------
   cairo_surface_destroy(cs)
   cairo_destroy(cr)
   return ""
end-- function conky_draw_test

