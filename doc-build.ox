#include "doc-build.oxh"

mreplace(tmplt,list) {
    decl txt = tmplt, r;
    foreach(r in list) txt = replace(txt,r[0],r[1]);
    return txt;
    }

/**Begin a list of sub-sections at level nlev.**/
document::lbeg(f,nlev,tclass) {
    fprintln(f,"<OL type=\"",ltypes[nlev],"\" class=\"toc",sprint(nlev),"\">");
    }
/**End a list of sub-sections.**/
document::lend(f) { fprintln(f,"</OL>"); }

/**Print the HTML header for a file, inserting book-specific tags.**/
document::printheader(h,title) {
        fprintln(h,mreplace(head0,{{atag,bkvals[BOOKAUTHOR]},{"<br/>",": "}}));
        fprintln(h,mathjax);
        fprintln(h,mreplace(headtitle,{{ttag,bkvals[BOOKTITLE]},{"<br/>",": "}}));
        }
document::printfooter(h,title,prev,next) {
    fprintln(h,mreplace(footer,{{"%prev%",prev},
                                {"%next%",next},
                                {"%tttag%",bkvals[BOOKTAG]+" "+title},
                                {atag,bkvals[BOOKAUTHOR]},
                                {"%year%",timestr(today())[:3]},
                                {"%affiliation%",bkvals[AFFILIATION]}
                                }));
    }


/**Create the cover page of the book, reading info from the TOC file.**/
titlepage::titlepage() {
    section(0);
    decl line, ch, pind,done;
    do {
       fscan(tocf,OxScan,&line);
       sscan(line,"%c",&ch);
       done = ch=='#';
       if (!done) {
            sscan(&line,"%T",&ch);
            pind=strfind(partags,ch[0]);
            if (pind!=FEND)
                {
            	sscan(&line,"%T",&ch);
				sscan(line,OxScan,&ch);
				bkvals[pind] = ch;
				println(pind," ",bkvals[pind]);
				}
            else println("parameter ",ch[0]," not found.");
            }
    } while (!done);
    title = bkvals[BOOKTITLE];
    pref = "";
    source = "title";
    output = source;
    made = FALSE;
    ord = 1;
    parent=-1;
    }

titlepage::make(inh) {
    if (isfile(inh)) {
        decl s,fp,line,inbody,nn;
        fprintln(inh,"<div class=\"tp\" style=\"background:url(img/titlepage.png) no-repeat  bottom center; background-size:70%;\" ><h1>",bkvals[BOOKTITLE],"</h1><h2>",bkvals[BOOKSUB],"</h2><br/>&nbsp;<br/><h3>",bkvals[BOOKAUTHOR],"<br/></h3><br/>Version ",bkvals[VERSION],"<br/>Printed: ","%C",dayofcalendar(),"<br/>&nbsp;</br>&nbsp;</br>#:  __________</div>");
        fprintln(inh,"<div class=\"preface\"><h1>Front Matter</h1><OL type=\"",ltypes[0],"\">");
        foreach (s in fm[nn])
           if (puboption>=s[MinLev]){
            fp = fopen(bdir+s[fmname]+outext,"r");
            if (isint(fp)) oxrunerror("output file "+bdir+s[fmname]+outext+" failed to open");
            if (nn==GLOSS) fprintln(inh,"<div class=\"break\"> </div>");
            fprintln(inh,"<h3><LI>",s[fmtitle],"</LI></h3><div ",nn!=GLOSS ? "id=\"split\">" : ">");
            inbody = FALSE;
            while(fscan(fp,OxScan,&line)>FEND) {
                if (!inbody)
                    inbody = strfind(line,"<body>")>-1;
                else {
                    if (strfind(line,"</body>")>-1)
                        inbody=FALSE;
                    else fprintln(inh,line);
                    }
                }
            fprintln(inh,"</div>");
            if (nn==TOC) fprintln(inh,"<div class=\"break\"> </div>");
            fclose(fp);
            }
        fprintln(inh,"</OL></div>");
        //fprintln(inh,"<OL type=\"I\"");
        made = TRUE;
        }
    else {
        decl h = fopen(bdir+output+outext,"w");
        if (isint(h)) oxrunerror("output file "+bdir+output+outext+" failed to open");
        printheader(h,bkvals[BOOKTITLE]);
        fprintln(h,"<div class=\"tp\"><h1>",bkvals[BOOKTITLE],"</h1><br/><h2>",bkvals[BOOKSUB],"</h2><h3>&nbsp;<br/>",bkvals[BOOKAUTHOR],"</h3></div>");
        printfooter(h,"","","001");
        //        fprintln(h,mreplace(footer,{{"%prev%",""},{"%next%","001"},}));
        fclose(h);
        }
    }

/**Exercises associated with a section.**/
exercises::exercises(sect) {
    section(0);
    notempty = FALSE;
    parent = sect;
    sect.myexer = this;
    level = 3;
    title = "Exercises for <em>"+parent.title+"</em>";
    pref = "ex";
    source = pref+sprint("%03u",parent.index);
    output = source;
    exdoc = fopen(sdir+source+inext,"w");
    if (isint(exdoc)) oxrunerror("output file "+sdir+source+inext+" failed to open");
    fprintln(exdoc,"<OL class=\"exer\">");
    }
exercises::accum(line) {    fprintln(exdoc,line);    }
exercises::append(ord,fn) {
    this.ord = ord+1;
    entry(fn);
    contents |= this;
    }
exercises::make(inh) {
    if (isfile(exdoc)) {
        fprintln(exdoc,"</OL>");
        fclose(exdoc);
        exdoc = 0;
        }
    section::make(inh);
    }
/** Parse a line from the **/
section::parse(line) {
    decl eb,ch;
    sscan(line,OxScan,&ch);
    eb = strfind(ch,rbr);
    title = ch[:eb-1];
    output = pref+sprint("%03u",index);
    if (eb<sizeof(ch)-2) {
        ch = ch[eb+1:];
        if (ch[0:0]==lp) {
            eb = strfind(ch,rp);
            source = ch[1:eb-1];
            }
        }
    }
section::entry(f) {
    fprintln(f,"<LI><a href=\"",output,outext,"\" target=\"contentx\">",title,"</a></LI>");
    }
section::glossentry(line) {
    if (isfile(fm[GLOSS][fptr])) {
        decl sb, se, ib, ie, tb,db,de,ipl;
        sb = strifind(line[0],dfcontl)+sizeof(dfcontl);
        se = strifindr(line[0],dfcontr)-1;
        db = strifind(line[0],dfbeg);
            ib = strifind(line[0][db:],"title=\"")+7;
            ie = strifind(line[0][db+ib:],"\"");
            tb = strifind(line[0][db+ib+ie:],">")+1;
            ipl = db+ib+ie+tb;
            de = ipl+strifind(line[0][ipl:],dfend)-1;
        fprint(fm[GLOSS][fptr],"<LI><a id=\"",line[0][ipl:de],"\" href=\"",output,outext,"#D",ndefn,"\" target=\"contentx\">");
        fprint(fm[GLOSS][fptr],line[0][ipl:de],"</a>");
        fprintln(fm[GLOSS][fptr],"<DD>",line[0][max(db+ib,0):max(0,db+ib,db+ib+ie-1)],"&emsp; &emsp;<em>See:",replace(title,"<br/>",":","i"),"</em></DD></LI>");
        line[0] = line[0][:ipl-2]+" id=\"D"+sprint(ndefn)+"\""+line[0][ipl-1:];
        ++ndefn;
    }
    }
exercises::entry(f) {
    fprintln(f,"<DT><a href=\"",output,outext,"\" target=\"contentx\">",title,"</a></DT>");
    }
exercises::eblock(href) {
    fprintln(exdoc,"<DD><a href=\"",href,"\" target=\"contentx\">&larr;</a></DD>");
	}
section::section(index) {
    this.index = index;
    pref = "s";
    ndefn = uplev = myexer = child = level =source = anch = 0;
    title = output = "";
    notempty = TRUE;
	minprintlev = OUTLINE;
    }
section::make(inh) {
    decl h,ftype,ftemp,notdone,curxname;
    ftype = 0;  //initialize to avoid error until first figure is found
	curxname = 0;
    if (isfile(inh)) {
         h = inh;
/*         if (ord==1) fprintln(h,"<OL  type=\"",ltypes[level],"\" class=\"toc",level,"\" >");
         else for(decl i=0;i<uplev;++i) lend(h);
         fprintln(h,"<h",level,"><a name=\"",output,"\"><LI>",title,"</LI></a></h",level,">");*/
         fprint(h,"<OL  type=\"",ltypes[level],"\" class=\"toc",level,"\" >");
         fprintln(h,"<h",level,"><a id=\"",output,"\"><LI value=",ord,">",title,"</LI></a></h",level,"></OL>");

         }
    else {
        h = fopen(bdir+output+outext,"w");
        if (isint(h)) oxrunerror("output file "+bdir+output+outext+" failed to open");
        printheader(h,title);
        fprintln(h,"\n<OL  type=\"",ltypes[level],"\" \">",
                   "<h",level,"><a id=\"",output,"\"><LI value=",ord,">",title,"</a></LI></h",sprint(level),"></OL>");
        }
    if (isstring(source)) {
        decl ss = fopen(sdir+source+inext,"r"),line,curtit = "", nsc,eof;
        if (isfile(ss)) {
            while(( (nsc=fscan(ss,OxScan,&line))>FEND)) {
                if (nsc==0) { if (puboption>=PUBLISH) fprintln(h,""); continue;}  //zero character line read in
                if (line==exstart) {   //Exercises beginning
                    if (isclass(exsec)) {
                        if (puboption>=PUBLISH) {
							fprintln(h,"<a id=\"EB",++curxname,"\"></a>");
							fprintln(h,exopen);
							exsec->eblock(output+outext+"#EB"+sprint(curxname));
							}
                        exsec.notempty = TRUE;
                        }
                    do {
                        eof = fscan(ss,OxScan,&line)==FEND;
						notdone = strfind(line,comend)==FEND;
                        if (notdone) {
                            if (isclass(exsec) ){
                                if (puboption>=PUBLISH) fprintln(h,line);
                                exsec->accum(line);
                                }
                            }
                        } while(notdone && !eof);
                    if (isclass(exsec) && puboption>=PUBLISH) fprintln(h,exclose);
                    }
                else {
                    if (line==keystart) {	//Key or Instructor note beginning
						if (puboption>=KEY) fprintln(h,keyopen);
						do {
                            eof = fscan(ss,OxScan,&line)==FEND;
							notdone = strfind(line,comend)==FEND;
                            if (puboption>=KEY&&notdone) fprintln(h,line);
                            } while (notdone && !eof);
                        if (puboption>=KEY) fprintln(h,keyclose);
                        }
                    else {	//Ordinary text
                        if ((sizeof(line)>fmlast && (ftemp=find(figmarks,line[:fmlast]))>-1)) {
                            ftype = ftemp;  // This sets ftype until a new figmark shows up
                            ++fign[ftype];
                            if (puboption>=PUBLISH) fprintln(h,"<a id=\"",figprefix[ftype],fign[ftype],"\"></a>");
							if (strfind(line,comend)==FEND) println("Error: ",comend,"\n",line);
                            curtit = line[fmlast+1:strfind(line,comend)-1];
                            if (isfile(fm[1+ftype][fptr]))
                                if (puboption>=PUBLISH) fprintln(fm[1+ftype][fptr],"<li><a href=\"",output+outext,"#",figprefix[ftype],fign[ftype],"\">",curtit,"</a></li>");
                            }
                        else {
                            if (strfind(line,dfbeg)>-1) glossentry(&line);
                            //next line uses current ftype, so figtag replace with the last one encountered
                            if (puboption>=PUBLISH)
                                fprintln(h,replace(line,figtag,"<h4>"+figtypes[ftype]+sprint(fign[ftype])+". "+curtit+"</h4>"));
                            }
                        }
                    }
                }
            fclose(ss);
            }
        else {
            oxwarning("Source file not found: "+source);
            if (puboption>=PUBLISH) fprintln(h,"<div class=\"break\"></div><blockquote class=\"upshot\"><h5>",title,"</h5> is not ready. This page is left blank to provide some room for taking notes.</blockquote><div class=\"break\"></div>");
            //notempty = FALSE;
            }
        }
    else if (level<2 && child>0) {
        if (puboption>=PUBLISH) fprintln(h,"<blockquote class=\"toc\"><h4>Contents</h4>");
        lbeg(h,level+1);
        decl c=index+1;
        do {
            if (contents[c].level==level+1 && contents[c].notempty) contents[c]->entry(h);
            } while (++c<sizeof(contents)&&contents[c].level>level);
        lend(h);
        if (puboption>=PUBLISH) fprintln(h,"</blockquote>");
        }
    if (!isfile(inh)) {
        if (puboption>=PUBLISH) {
                printfooter(h,title,sprint("%03u",index-1),sprint("%03u",index+1));
                }
        fclose(h);
        }
    }

section::slides() {
    decl h,ftype,ftemp;
    if (isstring(source)) {
        h = fopen(bdir+spref+output+outext,"w");
        if (isint(h)) oxrunerror("output file "+bdir+spref+output+outext+" failed to open");
        printheader(h,title);
        fprintln(h,"<OL  type=\"",ltypes[level],"\" \"><h",level,"><a id=\"",output,"\"><LI value=",ord,">",title,"</a></LI></h",sprint(level),"></OL>");
        decl ss = fopen(sdir+source+inext,"r"),line,curtit = "", nsc,eof;
        if (isfile(ss)) {
            while(( (nsc=fscan(ss,OxScan,&line))>FEND)) {
                if (nsc==0) { fprintln(h,""); continue;}  //zero character line read in
                if (line==exstart) {
                    if (isclass(exsec)) fprintln(h,exopen);
                    do {
                        eof = fscan(ss,OxScan,&line)==FEND;
                        if (line!=comend) {
                            if (isclass(exsec) ){
                                fprintln(h,line);
                                exsec->accum(line);
                                }
                            }
                        } while(line!=comend && !eof);
                    if (isclass(exsec) ) fprintln(h,exclose);
                    }
                else {
                    if ((sizeof(line)>fmlast && (ftype=find(figmarks,line[:fmlast]))>-1)) {
                         ++fign[ftype];
                         fprintln(h,"<a id=\"",figprefix[ftype],fign[ftype],"\"></a>");
                         curtit = line[sizeof(figmarks[ftype]):strfind(line,comend)-1];
                         }
//                    else{
//                       fprintln(h,replace(line,figtag,"Exhibit "+sprint(fign[ftype])+". "+curtit));
//                       }
                    }
                }
            fclose(ss);
            }
        printfooter(h,"",sprint("%03u",index-1),sprint("%03u",index+1));
        fclose(h);
        }
    }


document::build(sdir,bdir,tocfile,puboption) {
    decl done, htoc,  ind, book,  ch,line,n,iprev,sect,curp, curx,nlev;
    bkvals = new array[NBOOKPARAMS];
    fm =        {{"toc","Table of Contents",0,OUTLINE},
                {"figlist","List of Figures",0,PUBLISH},
                {"deflist","List of Definitions",0,PUBLISH},
                {"thlist","List of Theorems",0,PUBLISH},
                {"alglist","List of Algorithms",0,PUBLISH},
                {"tablist","List of Tables",0,PUBLISH},
                {"glossary","Glossary of Defined Terms &amp; Special Symbols",0,PUBLISH},
                {"codelist","List of Code Files",0,PUBLISH},
                {"imanual","Instructor Material",0,KEY}};
	document::puboption = puboption;
	figmarks = {};
    foreach (n in figtags) figmarks |= {comstart+n};
    figtag = comstart+"F"+"-->"; //<!--F-->",
    exstart = comstart+extag;
    keystart = comstart+keytag;
    lev = 0;
    if (sdir!="") this.sdir = sdir;
    if (bdir!="") this.bdir = bdir;
    if (tocfile!="") this.TOCFILE = tocfile+tocext;
    fign = zeros(sizerc(figmarks),1);
    fignicks = new array[sizerc(figmarks)];
    tocf = fopen(sdir+TOCFILE);
    if (isint(tocf)) oxrunerror("input file "+sdir+TOCFILE+" failed to open");
    sect = new titlepage();
    decl s;
    for(s =0; s<sizeof(fm); ++s)
       if (puboption>=fm[s][MinLev]) {
        fm[s][fptr] = fopen(bdir+fm[s][fmname]+outext,"w");
//        println("#### ",s," ",bdir+fm[s][fmname]+outext);
        if (isint(fm[s][fptr])) oxrunerror("output file "+bdir+fm[s][fmname]+outext+" failed to open");
        printheader(fm[s][fptr],bkvals[BOOKTITLE]);
        if (!s)
            fprintln(fm[s][fptr],"<span style=\"font-size:small;\">\n<details><summary>Contents</summary>"); //<h3>",fm[s][fmtitle],"</h3>
        else
            fprintln(fm[s][fptr],"<span>\n<h3>",fm[s][fmtitle],"</h3><OL>"); //
        }
    curx = curp = matrix(0);
    sect.title = bkvals[BOOKTITLE];
    contents = {sect};
    exsec = 0;
    do {
       fscan(tocf,OxScan,&line);
       sscan(line,"%c",&ch); 		//println(ch," ",line);
       done = ch==tocendtag;		// rest of toc file ignored
	   if (ch==skiptag)	continue;   // comment line in toc
       if (!done) {
            sect = new section(sizeof(contents));
            iprev = sect.index-1;
            nlev = 0;
            do {
                sscan(&line,"%c",&ch);
                if (ch==lvtag) ++nlev;
                } while(ch==lvtag);
            sscan(&line,"%1u",&ch);   //minimum print level for this section.
			sect.minprintlev = ch;
			sscan(&line,"%c",&ch,"%c",&ch);  //skip closing and opening bracket
            sect.level=nlev;
            if (nlev>contents[iprev].level) {
                sect.ord = 1;
                contents[iprev].child = sect.index;
                curp |= sect.parent = iprev;
                curx |= 0;
				if (puboption>=sect.minprintlev) {
                	if (nlev>=2) fprintln(fm[TOC][fptr],tocopen);
                	lbeg(fm[TOC][fptr],nlev);
					}
                ++lev;
                }
            else {
                sect.ord = contents[curx[nlev-1]].ord+1;
                curx[nlev-1] = sect.index;
                }
            }
        if (done) nlev = 1;
        while(nlev<lev) {
            if (puboption>=sect.minprintlev) {
				lend(fm[TOC][fptr]);
	            if (lev>=2) fprintln(fm[TOC][fptr],tocclose);
				}
            ++sect.uplev;
            --lev;
            curp = curp[:max(0,rows(curp)-2)];
            curx = curx[:max(0,rows(curp)-2)];
            }
        if (nlev==1) {
            if (isclass(exsec)&&puboption>=sect.minprintlev) {
                exsec->append(sect.ord+1,fm[TOC][fptr]);
//                lend(fm[0][fptr]);
                }
            }
        if (!done) {
            sect->parse(line);
            sect->entry(fm[TOC][fptr]);
            if (nlev==1) exsec = new exercises(sect);
            contents |= sect;
            }
        } while(!done);
//  lend(fm[TOC][fptr]);
  fprintln(fm[TOC][fptr],"</details></OL><hr/>");
  decl f;
  for (f=1;f<sizeof(fm);++f)
      if (puboption>=fm[f][MinLev])
        fprintln(fm[TOC][fptr],"<a href=\"",fm[f][fmname],outext,"\" target=\"contentx\">",fm[f][fmtitle],"</a><hr/>");
  fprintln(fm[TOC][fptr],"</span></body></html>");
  fclose(fm[TOC][fptr]); fm[TOC][fptr] = 0;
  foreach(s in contents[f]) {
    if (isclass(s.myexer)) exsec=s.myexer;
    if (puboption>=s.minprintlev) s->make(0);
    }
  exsec = 0;  //exercises already made.
  fign[] = 0;   // reset figure numbers
  htoc = fopen(bdir+"book"+outext,"w");
  for (f=TOC+1;f<sizeof(fm);++f)
  	if (isfile(fm[f][fptr])) {
		lend(fm[f][fptr]);
        fprintln(fm[f][fptr],"</span>");
        fclose(fm[f][fptr]);
        fm[f][fptr] = 0;
        }
  printheader(htoc,bkvals[BOOKTITLE]);
    //fprintln(htoc,replace(head,ttag,booktitle));
  foreach(s in contents[f])
  	if ( (!f||puboption>=PUBLISH) && s.notempty && puboption>=s.minprintlev) s->make(htoc);
  lend(htoc);
  fprintln(htoc,mreplace(footer,{ {"%prev%",""},{"%next%",""}}));
  fclose(htoc);
  htoc = 0;
  exsec = 0;  //exercises already made.
  fign[] = 0;   // reset figure numbers
  foreach(s in contents) if (s.notempty) s->slides();
  }
