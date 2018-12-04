/*

start C:\Users\User\Desktop\IS480\Project\AddMe.sql
*/
-- Create an enrollment package, contains an AddMe procedure and DropMe procedure. Checks various requirements for each procedure.

spool C:\Users\User\Desktop\IS480\Project\AddMeSpool.txt
set echo on
set serveroutput on

-- Creating spec for package Enroll
Create or replace package Enroll is
procedure AddMe(
	p_sNum number, 
	p_callNum number,
	p_errorMsg OUT varchar2);
	
function studentValid(
	p_sNum number)
	return number;
	
function callNumValid(
	p_callNum number)
	return number;
	
function repeatEnr(
	p_sNum number,
	p_callNum number)
	return number;
	
function doubleEnr(
	p_sNum number,
	p_callNum number)
	return number;

function underCreditHrLimit(
	p_sNum number,
	p_callNum number)
	return number;
	
function standingValid(
	p_sNum number,
	p_callNum number)
	return number;

end Enroll;
/

Create or replace package body Enroll is

procedure AddMe(
	p_sNum number, 
	p_callNum number,
	p_errorMsg OUT varchar2) is
	
	begin

	--1.1 Student is valid (exists)
	if studentValid(p_sNum) = 0 then
		p_errorMsg := 'Student is not valid. ';
	end if;
	
	-- 1.2 Call num is valid (exists)
	if callNumValid(p_callNum) = 0 then	
		p_errorMsg := p_errorMsg || 'Call number is not valid. ';
	end if;
	
	--Check if errormsg is null (student and callnum is valid), if null check other conditions
	if p_errorMsg is null then
	
		--2. Check for repeat enrollments (same callnum)
		if repeatEnr(p_sNum, p_callNum) = 0 then
			p_errorMsg := p_errorMsg || 'You are currently enrolled in this class (' ||p_callNum ||'). ';
		end if;
		
		--3. Check for double enrollments (same course, diff section number
		if doubleEnr(p_sNum, p_callNum) = 0 then
			p_errorMsg := p_errorMsg || 'Cannot enroll in another section of a course currently enrolled in. ';
		end if;
		
		--4. Check if class will put the student over 15hr credit limit
		if underCreditHrLimit(p_sNum, p_callNum) = 0 then
			p_errorMsg := p_errorMsg || 'Cannot enroll in more than 15 credit hours per semester. ';
		end if;
		
		--5. Check if student standing is >= course standing
		if standingValid(p_sNum, p_callNum) = 0 then
			p_errorMsg := p_errorMsg || 'Student standing dooes not permit enrollmnent in this course. ';
		end if;
	end if;
	
	end;
	
--1.1 Valid student number	
function studentValid(
	p_sNum number) 
	return number as
	v_sNumCount number;
	
	begin
	
	select count(*) into v_sNumCount
		from students
		where snum = p_sNum;
	
	if v_sNumCount = 0 then
		return 0;
	else
		return 1;
	end if;
	
	end;
-- 1.2 Valid callnumber	
function callNumValid(
	p_callNum number)
	return number as
	v_callNumCount number;
	
	begin
	
	select count(*) into v_callNumCount
		from schclasses
		where callnum = p_callNum;
		
	if v_callNumCount = 0 then
		return 0;
	else
		return 1;
	end if;
	
	end;

--2. Repeat enrollments, can't be enrolled in the same class
function repeatEnr(
	p_sNum number,
	p_callNum number)
	return number as
	
	v_enrCount number;
	
	begin
	
		select count(*) into v_enrCount
			from enrollments 
			where snum = p_sNum
			and callnum = p_callnum;
			
	if v_enrCount = 0 then
		return 1;
	else
		return 0;
	end if;
	
	end;

--3. Check for double enrollments (same course, diff section number
function doubleEnr(
	p_sNum number,
	p_callNum number)
	return number as
	
	v_dept varchar2(3);
	v_cNum number;
	enrCount number;
	
	Begin
	
	select sc.dept, sc.cNum into v_dept, v_cNum
		from schclasses sc
		where sc.callnum = p_callNum;
		
	select count(*) into enrCount
		from enrollments e, schclasses sc
		where e.snum = p_sNum
		and sc.dept = v_dept
		and sc.cnum = v_cNum
		and e.callnum = sc.callnum;
		
	if enrCount = 0 then
		return 1;
	else
		return 0;
		
	end if;
	
	end;
	
--4. Check if class will put the student under 15hr credit limit	
function underCreditHrLimit(
	p_sNum number,
	p_callNum number)
	return number as
	
	v_currentSum number;
	v_courseCreditHrs number;
	
	begin
	
	
	
	select sum(c.crhr) into v_currentSum
		from enrollments e, schclasses sc, courses c
		where e.snum = p_sNum
		and e.callnum = sc.callnum
		and sc.dept = c.dept
		and sc.cnum = c.cnum;
		
	if v_currentSum is null then
		v_currentSum := 0;
	end if;
	
	select crhr into v_courseCreditHrs
		from schclasses sc, courses c
		where sc.callnum = p_callNum
		and sc.dept = c.dept
		and sc.cnum = c.cnum;
		
	if (v_currentSum + v_courseCreditHrs) <= 15 then
		return 1;
	else
		return 0;
	end if;
	
	end;
	
--5. Check if student standing is >= to the course standing of p_callNum
function standingValid(
	p_sNum number,
	p_callNum number)
	return number as

	v_studentStanding number;
	v_courseStanding number;
	
	begin
	select standing into v_studentStanding
		from students
		where snum = p_snum; 
	
	select standing into v_courseStanding
		from schclasses sc, courses c
		where sc.callnum = p_callNum
		and sc.dept = c.dept
		and sc.cnum = c.cnum;
		
	if v_studentStanding >= v_courseStanding then
		return 1;
	else
		return 0;
	end if;
	
	end;
	
end Enroll;
/

spool off