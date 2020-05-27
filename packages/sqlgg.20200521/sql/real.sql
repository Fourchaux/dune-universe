 create table codeTable (locat INT, code TEXT, descript TEXT);

 select *
 from codeTable
 where locat not in (@lim1, @lim2)
 and code not in
   (
    select code
    from
      (select code, descript     // gets unique code-and-descript combos
       from codeTable
       where locat not in (@lim1, @lim2)
       group by code, descript
      )
    group by code
    having count(*) > @x     // (error? should be "="?)
   )
 order by code, locat;
