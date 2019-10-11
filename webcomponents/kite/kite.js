
function cngColour(evt) {
    if (gICAPI.svgDoc == null) {
        return;
    }
    var id = evt.target.getAttribute("id");
    evt.target.setAttribute("style",gICAPI.currentStyleToApply);
    if (gICAPI.memorizedData == "") {
        gICAPI.memorizedData = id + "=" + gICAPI.currentStyleToApply;
    } else {
        gICAPI.memorizedData = gICAPI.memorizedData + "\n" + id + "=" + gICAPI.currentStyleToApply;
    }
    gICAPI.SetFocus();
    gICAPI.SetData(gICAPI.memorizedData);
    gICAPI.Action("kiteupdated");
    
}

function setColour(evt) {
    if (gICAPI.svgDoc == null) {
        return;
    }
    gICAPI.currentStyleToApply = evt.target.getAttribute("style");
    var currentColourElt = gICAPI.svgDoc.getElementById("currentColour");
    if (currentColourElt == null) {
        return;
    }
    currentColourElt.setAttribute("style",gICAPI.currentStyleToApply );
    
}

function onICHostReady(version) {
    if ( version != 1.0 ) {
        alert('Invalid API version');
        return;
    }

    gICAPI.currentStyleToApply = "fill:#000000;";
    gICAPI.memorizedProps = "";
    gICAPI.memorizedData = "";
    gICAPI.redrawRequested = false;

    gICAPI.onData = function(data) {
        if (data == "") {
            var props = gICAPI.memorizedProps;
            gICAPI.memorizedProps = "";
            gICAPI.memorizedData = "";
            gICAPI.onProperty(props);
        } else if (data != gICAPI.memorizedData) {
            gICAPI.memorizedData = data;
            if (! gICAPI.redrawRequested) {
                gICAPI.redrawRequested = true;
                setTimeout(gICAPI.redrawKite,10);
            }
        } else {
            //alert("DEBUG:onData:ignored!");
        }
    }

    gICAPI.onProperty = function(props) {
        if (props != gICAPI.memorizedProps) {
            gICAPI.memorizedProps = props;
            document.getElementById('svg').innerHTML=
                "<embed id='embed' src='kite_"+eval('(' + props + ')').model+".svg' width='640px' height='452px' type='image/svg+xml' pluginspage='http://www.adobe.com/svg/viewer/install/'/>";
            if (! gICAPI.redrawRequested) {
                gICAPI.redrawRequested = true;
                setTimeout(gICAPI.redrawKite,10);
            }
        }
    }

    gICAPI.onFocus = function(polarity) {
        if ( polarity ) {
            document.getElementById('svg').style.border = '1px solid blue';
        } else {
            document.getElementById('svg').style.border = '1px solid grey';
        }
    }

    gICAPI.redrawKite = function() {
        gICAPI.redrawRequested = false;
        
        if (gICAPI.svgDoc == null) {
            var embed=document.getElementById("embed");
            gICAPI.svgDoc=embed != null ? embed.getSVGDocument() : null;
            if (gICAPI.svgDoc == null) {
                if (! gICAPI.redrawRequested) {
                    gICAPI.redrawRequested = true;
                    setTimeout(gICAPI.redrawKite,10);
                }
                return;
            }
        }
        var rows = gICAPI.memorizedData.split('\n');
        for (var i=0; i < rows.length; i++) {
            var panelAndColour = rows[i].split('=');
            if (panelAndColour.length == 2) {
                var panelElt = gICAPI.svgDoc.getElementById(panelAndColour[0]);
                if (panelElt != null) {
                    //alert("DEBUG: Set style ["+panelAndColour[1]+"] on panel #"+panelAndColour[0]);
                    panelElt.setAttribute("style", panelAndColour[1]);
                } else {
                    //alert("DEBUG: Panel #"+panelAndColour[0]+" not found in current kite");
                }
            }
        }
    }
}
