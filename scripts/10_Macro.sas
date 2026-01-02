/*****************************************
Trim or winsorize macro
byvar = none for no byvar
type  = delete or winsor
dsetin  = input dataset
dsetout = output dataset
vars  = variables to trim/winsor
pctl  = percentile cutoffs (e.g., 1 99)
******************************************/

%macro winsor(dsetin=, dsetout=, byvar=none, vars=, type=winsor, pctl=1 99);

    %if %superq(dsetout)= %then %let dsetout=&dsetin;

    %let varL=;
    %let varH=;
    %let xn=1;

    %do %while(%scan(&vars,&xn) ne );
        %let token=%scan(&vars,&xn);
        %let varL=&varL &token.L;
        %let varH=&varH &token.H;
        %let xn=%eval(&xn+1);
    %end;

    %let xn=%eval(&xn-1);

    data xtemp;
        set &dsetin;
    run;

    %if &byvar=none %then %do;
        data xtemp;
            set xtemp;
            xbyvar=1;
        run;
        %let byvar=xbyvar;
    %end;

    proc sort data=xtemp;
        by &byvar;
    run;

    proc univariate data=xtemp noprint;
        by &byvar;
        var &vars;
        output out=xtemp_pctl
            pctlpts=&pctl
            pctlpre=&vars
            pctlname=L H;
    run;

    data &dsetout;
        merge xtemp xtemp_pctl;
        by &byvar;

        array trimvars{&xn} &vars;
        array trimvarl{&xn} &varL;
        array trimvarh{&xn} &varH;

        do xi=1 to dim(trimvars);

            if not missing(trimvars{xi}) then do;

                %if &type=winsor %then %do;
                    if trimvars{xi} < trimvarl{xi} then trimvars{xi}=trimvarl{xi};
                    else if trimvars{xi} > trimvarh{xi} then trimvars{xi}=trimvarh{xi};
                %end;
                %else %do;
                    if trimvars{xi} < trimvarl{xi} then delete;
                    else if trimvars{xi} > trimvarh{xi} then delete;
                %end;

            end;

        end;

        drop &varL &varH xbyvar xi;
    run;

%mend winsor;
