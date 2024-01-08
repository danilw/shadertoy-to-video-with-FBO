// only change - at end of code fragColor.a = 1.0;
// this shader edited alpha set to 1.0, else image would be translarent

// Created by Danil (2021+) https://cohost.org/arugl

// License - CC0 or use as you wish



// using MIT License code
// using https://www.shadertoy.com/view/wtXfRH
// using https://www.shadertoy.com/view/ll2GD3


#define SS(x, y, z) smoothstep(x, y, z)
#define MD(a) mat2(cos(a), -sin(a), sin(a), cos(a))


// divx is number of lines on background
//#define divx floor(iResolution.y/15.)

const float divx = 35.;
#define polar_line_scale (2./divx)

const float zoom_nise = 9.;


// Common code moved for Cineshader support
//-------------Common code

// using MIT License code
// using https://www.shadertoy.com/view/wtXfRH
// using https://www.shadertoy.com/view/ll2GD3

mat3 rotx(float a){float s = sin(a);float c = cos(a);return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c));  }
mat3 roty(float a){float s = sin(a);float c = cos(a);return mat3(vec3(c, 0.0, s), vec3(0.0, 1.0, 0.0), vec3(-s, 0.0, c));}
mat3 rotz(float a){float s = sin(a);float c = cos(a);return mat3(vec3(c, s, 0.0), vec3(-s, c, 0.0), vec3(0.0, 0.0, 1.0 ));}

float linearstep(float begin, float end, float t) {
    return clamp((t - begin) / (end - begin), 0.0, 1.0);
}


float hash(vec2 p)
{
  vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return -1.+2.*fract((p3.x + p3.y) * p3.z);
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
  vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

float fbm( in vec2 p )
{
    p*=0.25;
    float s = 0.5;
    float f = 0.0;
    for( int i=0; i<4; i++ )
    {
        f += s*noise(p);
        s *= 0.8;
        p = 2.01*mat2(0.8,0.6,-0.6,0.8)*p;
    }
    return 0.5+0.5*f;
}

vec2 ToPolar(vec2 v)
{
    return vec2(atan(v.y, v.x)/3.1415926, length(v));
}

vec3 fcos( vec3 x )
{
    vec3 w = fwidth(x);
    return cos(x) * smoothstep(3.14*2.0,0.0,w);
 }

vec3 getColor( in float t )
{
    vec3 col = vec3(0.3,0.4,0.5);
    col += 0.12*fcos(6.28318*t*  1.0+vec3(0.0,0.8,1.1));
    col += 0.11*fcos(6.28318*t*  3.1+vec3(0.3,0.4,0.1));
    col += 0.10*fcos(6.28318*t*  5.1+vec3(0.1,0.7,1.1));
    col += 0.10*fcos(6.28318*t* 17.1+vec3(0.2,0.6,0.7));
    col += 0.10*fcos(6.28318*t* 31.1+vec3(0.1,0.6,0.7));
    col += 0.10*fcos(6.28318*t* 65.1+vec3(0.0,0.5,0.8));
    col += 0.10*fcos(6.28318*t*115.1+vec3(0.1,0.4,0.7));
    col += 0.10*fcos(6.28318*t*265.1+vec3(1.1,1.4,2.7));
    return col;
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

//----------end of Common

vec3 get_noise(vec2 p,float timer){
    vec2 res = iResolution.xy/iResolution.y;
    vec2 shiftx= res*0.5*1.25+.5*(0.5+0.5*vec2(sin(timer*0.0851),cos(timer*0.0851)));
    vec2 shiftx2= res*0.5*2.+.5*(0.5+0.5*vec2(sin(timer*0.0851),cos(timer*0.0851)));
    vec2 tp = p + shiftx;
    float atx = (atan(tp.x+0.0001*(1.-abs(sign(tp.x))),tp.y)/3.141592653)*.5+fract(timer*0.025);
    vec2 puv = ToPolar(tp);
    puv.y+=atx;
    puv.x*=0.5;
    vec2 tuv = puv*divx;
    float idx = mod(floor(tuv.y),divx)+200.;
    puv.y=fract(puv.y);
    puv.x=abs(fract(puv.x/divx)-0.5)*divx; // mirror seamless noise
    puv.x+=-.5*timer*(0.075-0.0025*max((min(idx,16.)+2.*sin(idx/5.)),0.));
    return vec3(SS(0.43,0.73,fbm(((p*0.5+shiftx2)*MD(-timer*0.013951*10./zoom_nise))*zoom_nise*2.+vec2(4.+2.*idx))),SS(0.543,0.73,fbm(((p*0.5+shiftx2)*MD(timer*0.02751*10./zoom_nise))*zoom_nise*1.4+vec2(4.+2.*idx))),fbm(vec2(4.+2.*idx)*puv*zoom_nise/100.));
}

vec4 get_lines_color(vec2 p, vec3 n, float timer){
    vec2 res = iResolution.xy/iResolution.y;
    
    vec3 col= vec3(0.);
    float a = 1.;
    
    vec2 shiftx= res*0.5*1.25+.5*(0.5+0.5*vec2(sin(timer*0.0851),cos(timer*0.0851)));
    vec2 tp = p + shiftx;
    float atx = (atan(tp.x+0.0001*(1.-abs(sign(tp.x))),tp.y)/3.141592653)*(0.5)+fract(timer*0.025);
    vec2 puv = ToPolar(tp);
    puv.y+=atx;
    puv.x*=0.5;
    vec2 tuv = puv*divx;
    float idx = mod(floor(tuv.y),divx)+1.;
    
    
    // thin lines
    float d = length(tp);
    d+=atx;
    float v = sin(3.141592653*2.*divx*0.5*d+0.5*3.141592653);
    float fv =fwidth(v);
    fv+=0.0001*(1.-abs(sign(fv)));
    d = 1.-SS(-1.,1., .3*abs(v)/fv);
    
    float d2 = 1.-SS(0., 0.473, abs(fract(tuv.y)-0.5));
    tuv.x+=3.5*timer*(0.01+divx/200.)-0.435*idx;
    
    // lines
    tuv.x=abs(fract(tuv.x/divx)-0.5)*divx;
    float ld = SS(0.1,.9,(fract(polar_line_scale*tuv.x*max(idx,1.)/10.+idx/3.)))*(1.-SS(0.98,1.,(fract(polar_line_scale*tuv.x*max(idx,1.)/10.+idx/3.))));
    
    tuv.x+=1.*timer*(0.01+divx/200.)-01.135*idx;
    ld *= 1.-SS(0.1,.9,(fract(polar_line_scale*tuv.x*max(idx,1.)/10.+idx/6.5)))*(1.-SS(0.98,1.,(fract(polar_line_scale*tuv.x*max(idx,1.)/10.+idx/6.5))));
    
    float ld2 = .1/(max(abs(fract(tuv.y)-0.5)*1.46,0.0001)+ld);
    ld = .1/((max(abs(fract(tuv.y)-0.5)*1.46,0.0001)+ld)*(2.5-(n.y+1.*max(n.y,n.z))));

    
    ld=min(ld,13.);
    ld*=SS(0.0,0.15,0.5-abs(fract(tuv.y)-0.5));
    
    // noise
    d*=n.z*n.z*2.;
    float d3=(d*n.x*n.y+d*n.y*n.y+(d2*ld2+d2*ld*n.z*n.z));
    d=(d*n.x*n.y+d*n.y*n.y+(d2*ld+d2*ld*n.z*n.z));
    
    a=clamp(d,0.,1.);
    
    
    puv.y=mix(fract(puv.y),fract(puv.y+0.5),SS(0.,0.1,abs(fract(puv.y)-0.5)));
    col = getColor( .54*length(puv.y) );
    
    col = 3.5*a*col*col+2.*(mix(col.bgr,col.grb,0.5+0.5*sin(timer*0.1))-col*0.5)*col;
    
    d3=min(d3,4.);
    d3*=(d3*n.y-(n.y*n.x*n.z));
    d3*=n.y/max(n.z+n.x,0.001);
    d3=max(d3,0.);
    vec3 col2 = .5*d3*vec3(0.3,0.7,0.98);
    col2=clamp(col2,0.,2.);
    
    col=col2*0.5*(0.5-0.5*cos((timer*0.48*2.)))+mix(col,col2,0.45+0.45*cos((timer*0.48*2.)));
    
    col=clamp(col,0.,1.);
    
    //col=vec3(ld);
    
    return vec4(col,a);
}

vec4 planet(vec3 ro, vec3 rd, float timer, out float cineshader_alpha)
{   
    vec3 lgt = vec3(-.523, .41, -.747);
    float sd= clamp(dot(lgt, rd)*0.5+0.5,0.,1.);
    float far = 400.;
    float dtp = 13.-(ro + rd*(far)).y*3.5;
    float hori = (linearstep(-1900., 0.0, dtp) - linearstep(11., 700., dtp))*1.;
    hori *= pow(abs(sd),.04);
    hori=abs(hori);
    
    vec3 col = vec3(0);
    col += pow(hori, 200.)*vec3(0.3, 0.7,  1.0)*3.;
    col += pow(hori, 25.)* vec3(0.5, 0.5,  1.0)*.5;
    col += pow(hori, 7.)* pal( timer*0.48*0.1, vec3(0.8,0.5,0.04),vec3(0.3,0.04,0.82),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25) )*1.;
    col=clamp(col,0.,1.);
    
    float t = mod(timer,15.);
    float t2 = mod(timer+7.5,15.);
    float td = .071*dtp/far+5.1;
    float td2 = .1051*dtp/far+t*.00715+.025;
    float td3 = .1051*dtp/far+t2*.00715+.025;
    vec3 c1=getColor(td);
    vec3 c2=getColor(td2);
    vec3 c3=getColor(td3);
    c2=mix(c2,c3.bbr,abs(t-7.5)/7.5);

    c2=clamp(c2,0.0001,1.);
    
    col+=sd*hori*clamp((c1/(2.*c2)),0.0,3.)*SS(0.,50.,dtp);
    col=clamp(col,0.,1.);
    
    float a=1.;
    a=(0.15+.95*(1.-sd))*hori*(1.-SS(.0,25.,dtp));
    a=clamp(a,0.,1.);
    
    hori = mix(linearstep(-1900., 0.0, dtp), 1. - linearstep(11., 700., dtp), sd);
    cineshader_alpha=1.-pow(hori,3.5);

    return vec4(col,a);
}

vec3 cam(vec2 uv, float timer)
{
    //vec2 res = (ires.xy / ires.y);
    //vec2 im = (mouse.xy) / ires.y - res/2.0;
    timer*=0.48;
    vec2 im = vec2(cos(mod(timer,3.1415926)),-0.02+0.06*cos(timer*0.17));
    im*=3.14159263;
    im.y = -im.y;
    
    float fov = 90.;
    float aspect = 1.;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.14159263 / 180.0)) / 2.0)));
    vec3 rd = normalize(vec3(uv*screenSize, 1./aspect));
    rd = (roty(-im.x) * rotx(im.y) * rotz(0.32*sin(timer*0.07))) * rd;
    return rd;
}


const mat3 ACESInputMat = mat3(
    0.59719, 0.35458, 0.04823,
    0.07600, 0.90834, 0.01566,
    0.02840, 0.13383, 0.83777
);

const mat3 ACESOutputMat = mat3(
     1.60475, -0.53108, -0.07367,
    -0.10208,  1.10813, -0.00605,
    -0.00327, -0.07276,  1.07602
);

vec3 RRTAndODTFit(vec3 v)
{
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}

vec3 ACESFitted(vec3 color)
{
    color = color * ACESInputMat;
    color = RRTAndODTFit(color);
    color = color * ACESOutputMat;
    color = clamp(color, 0.0, 1.0);
    return color;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0.);
    float timer = .65*iTime+220.;
    //timer=18.5*iMouse.x/iResolution.x;
    vec2 res = iResolution.xy/iResolution.y;
    vec2 uv = fragCoord.xy/iResolution.y-0.5*res;
    uv*=1.;
    vec3 noisev = get_noise(uv, timer);

    vec4 lcol = get_lines_color(uv, noisev, timer);

    //fragColor = vec4(lcol.rgba);

    vec3 ro = vec3(1.,40.,1.);
    vec3 rd = cam(uv, timer);
    float cineshader_alpha;
    vec4 planetc = planet(ro,rd,timer,cineshader_alpha);

    vec3 col = lcol.rgb*planetc.a*0.75+0.5*lcol.rgb*min(12.*planetc.a,1.)+planetc.rgb;
    col=clamp(col,0.,1.);
    
    fragColor = vec4(col*0.85+0.15*col*col,1.);
    
    // extra color correction
    fragColor.rgb = fragColor.rgb*0.15+fragColor.rgb*fragColor.rgb*0.65+(fragColor.rgb*0.7+0.3)*ACESFitted(fragColor.rgb);
    
    float tfc = fragCoord.x/iResolution.x-0.5;
    cineshader_alpha*=((1.-(tfc*tfc*4.))*0.15+0.85);
    fragColor.a = cineshader_alpha;
    //fragColor=vec4(cineshader_alpha);
    fragColor.a = 1.0;
    
}




