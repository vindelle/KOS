CLEARSCREEN.
SAS OFF.

PRINT "LngCheck.ks loaded".

PARAMETER Refaltitude.
PARAMETER RefShip.
PARAMETER Satnumber.

DECLARE FUNCTION TransferBurn {
	SET WARP TO 0.
	IF SHIP:APOAPSIS <= RefAltitude *0.95 {
		LOCK STEERING TO PROGRADE.
		WAIT 10.
		LOCK THROTTLE TO 1.0.
		WAIT UNTIL SHIP:APOAPSIS >= RefAltitude *0.95.
		LOCK THROTTLE TO 0.
	} ELSE IF SHIP:APOAPSIS >= RefAltitude * 1.05 {
		WAIT UNTIL ETA:PERIAPSIS <= 20.
		LOCK STEERING TO RETROGRADE.
		WAIT 10.
		LOCK THROTTLE TO 1.0.
		WAIT UNTIL SHIP:APOAPSIS <= RefAltitude * 1.05.
	} ELSE IF SHIP:PERIAPSIS <= RefAltitude * 0.95 AND SHIP:APOAPSIS >= RefAltitude *0.95 {
		WAIT 10.
		LOCK STEERING TO PROGRADE.
		SET WARP TO 3.
		WAIT UNTIL ETA:APOAPSIS <= 120.
		SET WARP TO 0.
		WAIT UNTIL ETA:APOAPSIS <= 20.
		LOCK THROTTLE TO 1.0.
		WAIT UNTIL SHIP:PERIAPSIS >= RefAltitude * 0.95.
		LOCK THROTTLE TO 0.
	}
}

DECLARE FUNCTION VecAng {
	SET v1 TO SHIP:POSITION-SHIP:BODY:POSITION.
	SET v2 TO VESSEL(RefShip):POSITION-SHIP:BODY:POSITION.

	SET CurrVec TO VectorAngle(v1,v2).
	IF PrevVec <> FALSE {
		IF PrevVec > CurrVec OR PrevVec < 0 {
			SET CurrVec TO -CurrVec.
		}
	}
}

DECLARE FUNCTION PrevV {
	PARAMETER Currvec.
	SET PrevVec TO CurrVec.
}

// Terminal display
WHEN SHIP:ELECTRICcharge >= 0.1 THEN {
	PRINT "Waiting until ship is " + LngStart + " offset " + RefShip AT (0,2).
	PRINT "Target ship longitude : " + ROUND(VESSEL(RefShip):longitude,0) AT (0,4).
	PRINT "Ship longitude : " + ROUND(SHIP:longitude,0) AT (0,5).
	PRINT "Current difference in longitude : " + ROUND(CurrVec,0) AT (0,6).
	PRESERVE.
}

// Setting transfer start condition
IF RefShip <> FALSE {
	SET demiGA TO (SHIP:ALTITUDE + RefAltitude + (BODY:RADIUS*2)).
	SET transferP TO 2 * constant:pi * sqrt(demiGA^3/BODY:mu).
	SET angleParcouru TO (360/(VESSEL(RefShip):orbit:period/(transferP/2))).
	SET angleDesire TO 360/Satnumber.
	SET angleAjoute TO angleDesire-angleParcouru.
	SET LngStart TO 180+angleAjoute.
	SET LngStart TO ROUND(LngStart).
	IF LngStart > 360 {
		SET LngStart TO LngStart - 180.
	} ELSE IF LngStart < 360 {
		SET LngStart TO LngStart + 180.
	}
}

SET PrevVec TO FALSE.

UNTIL SHIP:ORBIT:ECCENTRICITY <= 0.1 AND SHIP:ALTITUDE >= RefAltitude * 0.95 {

	IF RefShip <> FALSE {
		VecAng().
		UNTIL CurrVec <= LngStart + 1.5 AND CurrVec >= LngStart - 1.5 {
			SET WARP TO 3.
			WAIT 0.5.
			VecAng().
			PrevV(CurrVec).
		}
	}

	TransferBurn().
}

LOCK THROTTLE TO 0.

WAIT 10.

DELETE LngCheck.ks.

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
