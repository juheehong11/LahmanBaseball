-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;
DROP VIEW IF EXISTS binidhis;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), count(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), count(birthyear)
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, h.yearid
  FROM HallofFame AS h, People AS p
  WHERE p.playerID = h.playerID AND h.inducted = 'Y'
  ORDER BY h.yearid DESC, p.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT i.namefirst, i.namelast, i.playerid, ca.schoolid, i.yearid
  FROM q2i AS i INNER JOIN (SELECT c.playerid, c.schoolid
                              FROM CollegePlaying as c INNER JOIN Schools as s ON c.schoolid == s.schoolid
                              WHERE s.schoolstate = 'CA') AS ca ON i.playerid = ca.playerid
  ORDER BY i.yearid DESC, ca.schoolid ASC, ca.playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT i.playerid, i.namefirst, i.namelast, c.schoolid
  FROM q2i AS i LEFT JOIN CollegePlaying AS c ON i.playerid = c.playerid
  ORDER BY i.playerid DESC, c.schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, p.namefirst, p.namelast, b.yearid, (H-H2B-H3B-HR + 2*H2B + 3*H3B + 4*HR + 0.0)/(AB + 0.0) AS slg
  FROM  Batting AS b INNER JOIN People AS p ON p.playerid = b.playerid
  WHERE b.AB > 50
  ORDER BY slg DESC, b.yearid ASC, p.playerid ASC
  LIMIT 10
;

-- Question 3ii
DROP TABLE IF EXISTS battingdata;
CREATE VIEW battingdata(playerid, AB, H, H2B, H3B, HR)
AS
  SELECT playerid, SUM(AB), SUM(H), SUM(H2B), SUM(H3B), SUM(HR)
  FROM Batting
  GROUP BY playerid;

DROP TABLE IF EXISTS lslgcalc;
CREATE VIEW lslgcalc(playerid, lslg, AB)
AS
  SELECT playerid, (H-H2B-H3B-HR + 2*H2B + 3*H3B + 4*HR + 0.0)/(AB + 0.0) AS lslg, AB
  --FROM People AS p INNER JOIN battingdata AS s ON p.playerid = s.playerid
  FROM battingdata
  --WHERE AB > 50
;

CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT People.playerid, People.namefirst, People.namelast, lslgcalc.lslg
  FROM lslgcalc INNER JOIN People ON People.playerid = lslgcalc.playerid
  WHERE lslgcalc.AB > 50
  ORDER BY lslgcalc.lslg DESC, People.playerid ASC
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst, p.namelast, ii.lslg
  FROM lslgcalc AS ii INNER JOIN People AS p ON p.playerid = ii.playerid
  WHERE AB > 50 AND ii.lslg > (SELECT lslg
                     FROM lslgcalc
                     WHERE playerid = "mayswi01")
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM Salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW histogram(totalMin, totalMax, width)
AS
  SELECT MIN(salary), MAX(salary), CAST((MAX(salary) - MIN(salary))/10 AS INT)
  FROM Salaries
  WHERE yearid = 2016;

--CREATE VIEW binidhist(binid, mini, maxi, width)
--AS
--  SELECT binid, totalMIN + binid*width, totalMIN + (binid+1)*width, width
--  FROM binids, histogram
--;

CREATE VIEW bh(binid, mini, maxi, width)
AS
  SELECT binid, totalMIN + binid*width, totalMIN + (binid+1)*width, width
  FROM binids LEFT JOIN histogram
;

CREATE VIEW stc(binid, c)
AS 
  SELECT binid, count(*) as c
  FROM bh, salaries
  WHERE yearid = 2016 AND salary BETWEEN mini AND maxi
  GROUP BY bh.binid
  ;

CREATE VIEW q4ii(binid, low, high, count)
AS
  SELECT bh.binid, bh.mini, bh.maxi, stc.c
  FROM bh LEFT OUTER JOIN stc ON bh.binid = stc.binid
  --WHERE salary BETWEEN mini + binid*width AND mini + (binid+1)*width AND yearid = 2016
  --WHERE yearid = 2016 AND salary BETWEEN mini AND maxi
  GROUP BY bh.binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT two.yearid, two.min - one.min, two.max - one.max, two.avg - one.avg
  FROM q4i AS one, q4i AS two
  WHERE two.yearid - one.yearid = 1
  ORDER BY two.yearid ASC
;

-- Question 4iv

CREATE VIEW maxi2000(maxi)
AS
  SELECT MAX(salary)
  FROM Salaries
  WHERE yearid = 2000
;
CREATE VIEW maxi2001(maxi)
AS
  SELECT MAX(salary)
  FROM Salaries
  WHERE yearid = 2001
;
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT People.playerid, People.namefirst, People.namelast, salary, yearid
  FROM People INNER JOIN Salaries ON People.playerid = Salaries.playerid, maxi2000, maxi2001
  WHERE (yearid = 2000 AND salary >= maxi2000.maxi) OR (yearid = 2001 AND salary >= maxi2001.maxi)

;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT star.teamid, MAX(sal.salary) - MIN(sal.salary)
  FROM allstarfull AS star INNER JOIN Salaries AS sal ON star.playerid = sal.playerid --AND star.yearid = sal.playerid
  WHERE sal.yearID = 2016 AND star.yearID = 2016
  GROUP BY star.teamID
;

