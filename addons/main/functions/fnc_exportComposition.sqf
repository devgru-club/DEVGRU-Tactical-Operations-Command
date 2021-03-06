/*
Author:
Nicholas Clark (SENSEI)

Description:
export base data from 3DEN, should be used in VR map

Arguments:

Return:
nothing
__________________________________________________________________*/
#include "script_component.hpp"
#define CONFIG (configfile >> QGVARMAIN(compositions))
#define PRINT_MSG(MSG) titleText [MSG, "PLAIN"]
// #define ATTRIBUTE_SNAP(ENTITY) (parseNumber ((ENTITY get3DENAttribute QGVAR(snap)) select 0))
#define ATTRIBUTE_VECTORUP(ENTITY) (parseNumber ((ENTITY get3DENAttribute QGVAR(vectorUp)) select 0))
#define ATTRIBUTE_SIMPLE(ENTITY) (parseNumber ((ENTITY get3DENAttribute "objectIsSimple") select 0))
#define ANCHOR_CHECK(ENTITY) (typeOf ENTITY isEqualTo "Sign_Arrow_F")
#define NODE_CHECK(ENTITY) (typeOf ENTITY isEqualTo "Sign_Arrow_Blue_F")
#define NODE_MAXDIST 51
#define GET_POS_RELATIVE(ENTITY) (_anchor worldToModel (getPosATL ENTITY))
#define GET_DIR_OFFSET(ENTITY) (((getDir ENTITY) - (getDir _anchor)) mod 360)
#define GET_DATA(ENTITY) _composition pushBack [typeOf ENTITY,str GET_POS_RELATIVE(ENTITY),str (0 max ((getPosATL ENTITY) select 2)),str GET_DIR_OFFSET(ENTITY),ATTRIBUTE_VECTORUP(ENTITY),ATTRIBUTE_SIMPLE(ENTITY)]

// reset ui vars
uiNamespace setVariable [QGVAR(compExportDisplay),displayNull];
GVAR(compExportSel) = "";

if !(COMPARE_STR(worldName,"VR")) exitWith {
    PRINT_MSG("you must export compositions from VR map");scriptN
};

private _composition = [];
private _selected = get3DENSelected "object";
private _nodes = [];
private _strength = 0;
private _count = 0;
private _r = 0;
private _anchor = objNull;
private _br = toString [13,10];
private _tab = "    ";

// get composition anchor
{
    if (ANCHOR_CHECK(_x)) exitWith {
        _anchor = _x;
        // make sure anchor is snapped to terrain
        _anchor setPosATL [(getPosATL _anchor) select 0,(getPosATL _anchor) select 1,0];
        _anchor setVectorUp [0,0,1];
    };
} forEach _selected;

if (isNull _anchor) exitWith {
    PRINT_MSG("cannot export composition while anchor is undefined");
};

// get nodes (safe areas)
{
    if (NODE_CHECK(_x)) then {
        for "_i" from 2 to NODE_MAXDIST step 1 do {
            private _near = nearestObjects [_x, [], _i];
            if (count _near > 1 || {_i isEqualTo NODE_MAXDIST}) exitWith {
                _nodes pushBack [str GET_POS_RELATIVE(_x), str (_i - 1)];
            };
        };
    };
} forEach _selected;

// save object data
{
    if (!NODE_CHECK(_x) && {!ANCHOR_CHECK(_x)} && {!(_x isKindOf "Man")}) then {
        // save raw z value separately as model-space z value is inaccurate
        GET_DATA(_x);
        // adjust max radius
        _r = (round (_x distance2D _anchor)) max _r;
        // increase count for structural types and vehicles
        if (_x isKindOf "Building" || {_x isKindOf "AllVehicles"}) then {
            _count = _count + 1;
        };   
    };
} forEach _selected;

_strength = round (_r + (_count * 0.5));

// create type listbox
[_br,_tab,_composition,_nodes,_r,_strength] spawn {
    params ["_br","_tab","_composition","_nodes","_r","_strength"];

    closeDialog 2; 

    private _display = findDisplay 313 createDisplay "RscDisplayEmpty";
    uiNamespace setVariable [QGVAR(compExportDisplay),_display];

    private _title = _display ctrlCreate ["RscText", 100];
    _title ctrlSetPosition [0.7, 0.3, 0.5, 0.05];
    _title ctrlCommit 0;
    _title ctrlSetText "Select Composition Type";

    private _dropdown = _display ctrlCreate ["CtrlCombo", 101];
    _dropdown ctrlSetPosition [0.7, 0.37, 0.5, 0.05];
    _dropdown ctrlCommit 0;

    private ["_name","_item","_cfgName"];

    for "_i" from 0 to (count CONFIG) - 1 do {
        _name = configName (CONFIG select _i);
        _item = _dropdown lbAdd _name;
        _dropdown lbSetData [_item, _name];
    };

    _dropdown ctrlAddEventHandler ["LBSelChanged", {
        params ["_control", "_selectedIndex"];
        
        (uiNamespace getVariable [QGVAR(compExportDisplay),displayNull]) closeDisplay 1;
        GVAR(compExportSel) = _control lbData (lbCurSel _control);
    }];

    waitUntil {isNull _display};

    // compile class text and copy to clipboard
    for "_i" from 0 to (count CONFIG) - 1 do {
        _cfgName = configName (CONFIG select _i);
        if (COMPARE_STR(GVAR(compExportSel),_cfgName)) exitWith {
            // use config count on first call, else use count var
            ISNILS(GVAR(compExportCount),count (CONFIG select _i));

            private _className = format ["GVARMAIN(DOUBLES(%1,%2))",_cfgName,[count (CONFIG select _i),GVAR(compExportCount)] select (GVAR(compExportCount) > 0)];
            private _compiledEntry = [
                format ["class %3 {%1%2radius = %4;%1%2strength = %5;%1%2nodes = ",_br,_tab,_className,_r,_strength],
                str (str _nodes),
                format [";%1%2objects = ", _br,_tab],
                str (str _composition),
                format [";%2%1};", _br,_tab]
            ] joinString "";

            copyToClipboard _compiledEntry;

            private _msg = format ["Exporting %1 composition to clipboard: radius: %2, strength: %3, nodes: %4",_cfgName, _r, _strength, count _nodes];
            PRINT_MSG(_msg);  

            GVAR(compExportCount) = GVAR(compExportCount) + 1;
        };
    };
};

nil