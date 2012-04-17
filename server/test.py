#!/usr/bin/python
import optparse
import sys
# Install the Python unittest2 package before you run this script.
import unittest2

def main():
    sys.path.insert(0, "/Applications/GoogleAppEngineLauncher.app/Contents/Resources/GoogleAppEngine-default.bundle/Contents/Resources/google_appengine")
    sys.path.insert(0, "/home/prashn64/Downloads/google_appengine")
    sys.path.insert(0, "/home/prashn64/Downloads/appengine-ndb-experiment")
    import dev_appserver
    dev_appserver.fix_sys_path()
    suite = unittest2.loader.TestLoader().loadTestsFromName('database_test')
    unittest2.TextTestRunner(verbosity=2).run(suite)
    
    suite2 = unittest2.loader.TestLoader().loadTestsFromName('handlers_test')
    unittest2.TextTestRunner(verbosity=2).run(suite2)


if __name__ == '__main__':
    main()
