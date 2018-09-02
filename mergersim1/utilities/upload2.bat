cd upload
copy ..\..\mergersim.ado
copy ..\..\mergersim*.class
copy ..\..\mergersim.sthlp
copy ..\..\mergersim.pkg
copy ..\..\stata.toc
copy ..\..\example.do 
copy ..\..\cars1.dta 
copy c:\ado\personal\lmergersim.mlib
psftp Space2u -b ../upload2.scr 
del *.* /Q
cd ..