/*******************************************************************************
* Copyright (c) 2013-2021 "Filippo Scognamiglio"
* https://github.com/Swordfish90/cool-retro-term
*
* This file is part of cool-retro-term.
*
* cool-retro-term is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*******************************************************************************/
import QtQuick 2.0

import "utils.js" as Utils

ShaderEffect {
    property color _staticFrameColor: "#ffffff"
    property color _backgroundColor: appSettings.backgroundColor
    property color _fontColor: appSettings.fontColor
    property color _lightColor: Utils.mix(_fontColor, _backgroundColor, 0.2)
    property real _ambientLight: Utils.lint(0.2, 0.8, appSettings.ambientLight)

    property color frameColor: Utils.mix(_staticFrameColor, _lightColor, _ambientLight)
    property real screenCurvature: appSettings.screenCurvature * appSettings.screenCurvatureSize
    property real shadowLength: 0.5 * screenCurvature * Utils.lint(0.50, 1.5, _ambientLight)

    property size aadelta: Qt.size(1.0 / width, 1.0 / height)

    ShaderLibrary {
        id: shaderLibrary
    }

    fragmentShader: "
        #ifdef GL_ES
            precision mediump float;
        #endif

        uniform lowp float screenCurvature;
        uniform lowp float shadowLength;
        uniform highp float qt_Opacity;
        uniform lowp vec4 frameColor;
        uniform mediump vec2 aadelta;

        varying highp vec2 qt_TexCoord0;

        vec2 distortCoordinates(vec2 coords){
            vec2 cc = (coords - vec2(0.5));
            float dist = dot(cc, cc) * screenCurvature;
            return (coords + cc * (1.0 + dist) * dist);
        }
        " +

        shaderLibrary.max2 +
        shaderLibrary.min2 +
        shaderLibrary.prod2 +
        shaderLibrary.sum2 +

        "

        void main(){
            vec2 staticCoords = qt_TexCoord0;
            vec2 coords = distortCoordinates(staticCoords);

            vec3 color = vec3(0.0);
            float alpha = 0.0;

            float outShadowLength = shadowLength;
            float inShadowLength = shadowLength * 0.5;

            float outShadow = max2(1.0 - smoothstep(vec2(-outShadowLength), vec2(0.0), coords) + smoothstep(vec2(1.0), vec2(1.0 + outShadowLength), coords));
            outShadow = clamp(sqrt(outShadow), 0.0, 1.0);
            color += frameColor.rgb * outShadow;
            alpha = sum2(1.0 - smoothstep(vec2(0.0), aadelta, coords) + smoothstep(vec2(1.0) - aadelta, vec2(1.0), coords));
            alpha = clamp(alpha, 0.0, 1.0) * mix(1.0, 0.9, outShadow);

            float inShadow = 1.0 - prod2(smoothstep(0.0, inShadowLength, coords) - smoothstep(1.0 - inShadowLength, 1.0, coords));
            inShadow = 0.5 * inShadow * inShadow;
            alpha = max(alpha, inShadow);

            gl_FragColor = vec4(color * alpha, alpha);
        }
    "

    onStatusChanged: if (log) console.log(log) //Print warning messages
}
