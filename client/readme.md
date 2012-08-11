#Client Side

##Idiosyncrasies
###File Structure
####bootstrap
This holds all the components of Twitter Bootstrap, which we use for its components and base css.
#####Inside bootstrap
This bootstrap installation is customized to include everything except icons. This is because for icons, we use font-awesome.
######css
Note: To make use of the responsive title bar, custom padding had to be added to the css between the bootstrap base css and the bootstrap responsive css.  To make Meteor load these things in particular order, I structured the files like this:  
````
                  .--lib    
                 /     \--bootstrap.min.css    
            .--lib    
           /     \--between.css    
      .--css    
     /     \--bootstrap-responsive.min.css    
    /    
````
Meteor will load css files from deep to shallow, always traversing into lib folders first and reading main.*'s last.
######img
We no longer need this folder because we're not using any of the images in it.  But, it's still here because it might be referenced in the bootstrap css somewhere even if it shouldn't be, and I didn't want to delete the folder until we've tested that we don't need it and made any changes that we needed to.  
######js
Contains minified bootstrap js (various plugins we may end up using.)  If we don't end up using some of them, I can re-download only what we need.  However, I downloaded the full package, to ease development.  
####font-awesome
This contains the css needed to use font-awesome icons by classname.  The font(s) used by this are located in /res/font/.
####res
This contains the raw resources (art assets) that are included in the client.  So far, this is very little.  (just font-awesome.)  If we add images (we probably will, if only for the logo),  then those will go in /res/img/.
####socrenchus
And here is the code that we wrote specifically for socrenchus to work.  