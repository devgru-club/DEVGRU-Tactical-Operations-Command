/*
Author:
Nicholas Clark (SENSEI)

Description:
get object curator cost

Arguments:
0: object classname <STRING>

Return:
number
__________________________________________________________________*/
#include "script_component.hpp"

private ["_cost","_vehClass"];

_cost = 0;

call {
    _vehClass = toLower getText (configFile >> "CfgVehicles" >> (_this select 0) >> "vehicleClass");

    if (_vehClass in ["men","menstory","menrecon","mendiver","mensniper","mensupport"]) exitWith {
        _cost = FOB_COST_MAN
    };
    if (_vehClass in ["car","support"]) exitWith {
        _cost = FOB_COST_CAR
    };
    if (_vehClass in ["armored"]) exitWith {
        _cost = FOB_COST_TANK
    };
    if (_vehClass in ["air"]) exitWith {
        _cost = FOB_COST_AIR
    };
    if (_vehClass in ["ship","submarine"]) exitWith {
        _cost = FOB_COST_SHIP
    };
    /*if (_vehClass in ["ammo"]) exitWith {
        _cost = FOB_COST_AMMO
    };*/
    if (_vehClass in [/*"structures",*/"structures_military","structures_village","structures_infrastructure","structures_industrial","lamps"]) exitWith {
        _cost = FOB_COST_STRUCT
    };
    if (_vehClass in ["fortifications"]) exitWith {
        _cost = FOB_COST_FORT
    };
    /*if (_vehClass in ["signs"]) exitWith {
        _cost = FOB_COST_SIGN
    };*/
    /*if (_vehClass in ["small_items","objects","furniture","tents"]) exitWith {
        _cost = FOB_COST_ITEM
    };*/
};

_cost
