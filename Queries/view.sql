-- NAME: I GUSTI NGURAH AGUNG KRESNA
-- STUDENT ID: 11164605

CREATE VIEW gameView AS
SELECT
(SELECT G.Game FROM GameRound G
WHERE P.PlayerID = G.CurrentPlayerID
ORDER BY G.Game DESC LIMIT 1
) AS GameRound,
P.PlayerID, P.Player, P.BankBalance, P.IsPlaying, 
COALESCE(Pr.Property, B.Bonus) AS CurrentLocation,
(SELECT GROUP_CONCAT(Pr.Property, ', ')
FROM Property Pr
WHERE P.PlayerID = Pr.OwnerID
) AS OwnedProperty
FROM Player P
LEFT JOIN PropertyLocation Pl ON P.LocationID = Pl.LocationID
LEFT JOIN BonusLocation Bl on P.LocationID = Bl.LocationID
LEFT JOIN Property Pr ON Pl.PropertyID = Pr.PropertyID
LEFT JOIN Bonus B ON Bl.BonusID = B.BonusID
;