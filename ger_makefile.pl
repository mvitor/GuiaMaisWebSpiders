use ExtUtils::MakeMaker;

WriteMakefile(
	   'NAME'          => 'guiamais',
	   'VERSION'       => '0.10',
		     
	   'EXE_FILES'     =>  [ 'guiamais' ],
			          
	   'PREREQ_PM'     => {},

	   'INSTALLSCRIPT' => "$ENV{HOME}/bin",
		  );

