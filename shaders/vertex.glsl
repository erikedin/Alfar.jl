#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

out vec3 ourColor;

uniform vec4 rotation;
uniform vec3 translation;

vec4 qtmult(vec4 p, vec4 q)
{
    // p = (x, y, z, w)
    // q = (x, y, z, w)
    // p*q = (p.w + p.x*i + p.y*j + p.z*k)(q.w + q.x*i + q.y*j + q.z*k)
    //     =  p.w*q.w + p.w*q.x*i + p.w*q.y*j + p.w*q.z*k +
    //       -p.x*q.x + p.x*q.w*i - p.x*q.z*j + p.x*q.y*k +
    //       -p.y*q.y + p.y*q.z*i + p.y*q.w*j - p.y*q.x*k +
    //       -p.z*q.z - p.z*q.y*i + p.z*q.x*j + p.z*q.w*k
    return vec4(
        p.w*q.x + p.x*q.w + p.y*q.z - p.z*q.y,
        p.w*q.y - p.x*q.z + p.y*q.w + p.z*q.x,
        p.w*q.z + p.x*q.y - p.y*q.x + p.z*q.w,
        p.w*q.w - p.x*q.x - p.y*q.y - p.z*q.z
    );
}

vec4 qtinverse(vec4 q)
{
    return vec4(-q.x, -q.y, -q.z, q.w);
}

vec4 rotate(vec4 v)
{
    // Rotation is done by q*v*inv(q)
    // and in the case of unit quaternions inv(q) = q*
    return qtmult(rotation, qtmult(v, qtinverse(rotation)));
}

void main()
{
    vec4 p = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    gl_Position = vec4(translation, 0.0) + rotate(p);
    ourColor = aColor;
}