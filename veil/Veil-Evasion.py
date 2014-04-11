#!/usr/bin/python2

"""
Front end launcher for the Veil AV-evasion framework.

Handles command line switches for all options.
A modules.commoncontroller.Controller() object is instantiated with the
appropriate switches, or the interactive menu is triggered if no switches
are provided.
"""

# Import Modules
import sys, argparse, time, os, base64, socket
try:
    import symmetricjsonrpc
except ImportError:
    print '========================================================================='
    print ' Necessary install component missing'
    print ' Re-running ./setup/setup.sh'
    print '========================================================================='
    time.sleep(3)
    os.system('cd setup && ./setup.sh')
    try:
        import symmetricjsonrpc
    except ImportError:
        print '\n [!] Error importing pip'
        print " [!] Please run 'pip install symmetricjsonrpc' manually\n"
        sys.exit()

from modules.common import controller
from modules.common import messages
from modules.common import supportfiles
from modules.common import helpers


"""
The RPC-handler code.

The RPC requests are as follows:
    method="version"            -   return the current Veil-Evasion version number
    method="payloads"           -   return all the currently loaded payloads
    method="payload_options"
        params="payload_name"   -   return the options for the specified payload
    method="generate"
        params=["payload=X",    -   generate the specified payload with the given options
                "outputbase=Y"
                "overwrite=Z",
                "msfpayload=...",
                "LHOST=blah]

The return value will be the path to the generated executable.

You can start the server with "./Veil-Evasion.py --rpc" and shut it down with
    "./Veil-Evasin.py --rpcshutdown"

"""
class VeilEvasionServer(symmetricjsonrpc.RPCServer):
    class InboundConnection(symmetricjsonrpc.RPCServer.InboundConnection):
        class Thread(symmetricjsonrpc.RPCServer.InboundConnection.Thread):
            class Request(symmetricjsonrpc.RPCServer.InboundConnection.Thread.Request):

                # handle an RPC notification
                def dispatch_notification(self, subject):
                    print "dispatch_notification(%s)" % (repr(subject),)
                    # Shutdown the server.
                    print "[!] Shutting down Veil-Evasion RPC server..."
                    self.parent.parent.parent.shutdown()

                # handle an RPC request
                def dispatch_request(self, subject):
                    print "dispatch_request(%s)" % (repr(subject),)

                    try:
                        # extract the method name and associated parameters
                        method = subject['method']
                        params = subject['params']

                        # instantiate a main Veil-Evasion controller
                        con = controller.Controller(oneRun=False)

                        # handle a request for version
                        if method == "version":
                            return messages.version

                        # handle a request to list all payloads
                        elif method == "payloads":
                            payloads = []
                            # return a list of all available payloads, no params needed
                            for (name, payload) in con.payloads:
                                payloads.append(name)
                            return payloads

                        # handle a request to list a particular payload's options
                        elif method == "payload_options":
                            # returns options available for a particular payload
                            options = []

                            if len(params) > 0:
                                # nab the payload name
                                payloadname = params[0]

                                # find this payload from what's available
                                for (name, payload) in con.payloads:

                                    if payloadname.lower() == name.lower():
                                        p = payload
                                        # see what required options are available
                                        if hasattr(p, 'required_options'):
                                            for key in sorted(p.required_options.iterkeys()):
                                                # return for the option - name,default_value,description
                                                options.append( (key, p.required_options[key][0], p.required_options[key][1]) )
                                        # check if this is a shellcode-utilizing payload
                                        if hasattr(p, 'shellcode'):
                                            options.append("shellcode")
                            return options

                        # handle a request to generate a payload
                        elif method == "generate":
                            
                            if len(params) > 0:
                                payloadName,outputbase = "", ""
                                overwrite = False
                                payload = None
                                options = {}
                                options['required_options'] = {}

                                # pull these metaoptions out first
                                try:
                                    for param in params:
                                        if param.startswith("payload="):
                                            t,payloadName = param.split("=")
                                        elif param.startswith("outputbase="):
                                            t,outputbase = param.split("=")
                                        elif param.startswith("overwrite="):
                                            t,choice = param.split("=")
                                            if choice.lower() == "true":
                                                overwrite = True
                                except:
                                    return ""

                                # find our payload in the controller object list
                                for (name, p) in con.payloads:
                                    if payloadName.lower() == name.lower():
                                        payload = p

                                # error checking
                                if not payload: return ""

                                # parse all the parameters
                                for param in params:

                                    # don't include these metaoptions
                                    if param.startswith("payload=") or param.startswith("outputbase=") or param.startswith("overwrite="):
                                        continue 

                                    # extract the name/value from this parameter
                                    name,value = param.split("=")
                                    required_options = []

                                    # extract the required options if they're there
                                    if hasattr(payload, 'required_options'):
                                        required_options = payload.required_options.iterkeys()

                                    # if the value we're passed is in the required options
                                    if name in required_options:
                                        options['required_options'][name] = [value, ""]
                                    elif name == "shellcode":
                                        options['customShellcode'] = value
                                    elif name == "msfpayload" or name == "msfvenom":
                                        options['msfvenom'] = [value, []]

                                    # assume we have msfvenom options otherwise
                                    else:
                                        # temporarily get the msfoptions out
                                        t = options['msfvenom']
                                        if not t[1]:
                                            # if there are no existing options
                                            options['msfvenom'] = [t[0], [str((name+"="+value))] ]
                                        else:
                                            # if there are, append
                                            options['msfvenom'] = [t[0], t[1] + [str((name+"="+value))] ]

                                # manually set the payload in the controller object
                                con.SetPayload(payloadName, options)

                                # generate the payload code
                                code = con.GeneratePayload()

                                # write out the payload code to the proper output file
                                outName = con.OutputMenu(con.payload, code, showTitle=False, interactive=False, overwrite=overwrite, OutputBaseChoice=outputbase)

                                # return the written filename
                                return outName

                            else:
                                return ""
                        else:
                            return ""
                    except:
                        return ""


def runRPC(port=4242):
    """
    Invoke a Veil-Evasion RPC instance on the specified port.
    """

    print "[*] Starting Veil-Evasion RPC server..."
    # Set up a TCP socket
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    #  Start listening on the socket for connections
    s.bind(('', port))
    s.listen(1)

    # Create a server thread handling incoming connections
    server = VeilEvasionServer(s, name="VeilEvasionServer")

    # Wait for the server to stop serving clients
    server.join()


def shutdownRPC(port=4242):
    """
    Shutdown a running Veil-Evasion RPC server on a specified port.
    """

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    #  Connect to the server
    s.connect(('localhost', 4242))

    # Create a client thread handling for incoming requests
    client = symmetricjsonrpc.RPCClient(s)

    # shut the server down
    client.notify("shutdown")
    client.shutdown()
    print "[!] Veil-Evasion RPC server shutdown"


if __name__ == '__main__':
    try:
        # keep Veil.pyc from appearing?
        sys.dont_write_bytecode = True

        parser = argparse.ArgumentParser()
        parser.add_argument('-p', metavar="PAYLOAD", nargs='?', const="list", help='Payload to generate. Lists payloads if none specified.')
        parser.add_argument('-c', metavar='OPTION=value', nargs='*', help='Custom payload module options.')
        parser.add_argument('-o', metavar="OUTPUTBASE", default="payload", help='Output file base for source and compiled .exes.')
        parser.add_argument('--msfpayload', metavar="windows/meterpreter/reverse_tcp", nargs='?', help='Metasploit shellcode to generate.')
        parser.add_argument('--msfoptions', metavar="OPTION=value", nargs='*', help='Options for the specified metasploit payload.')
        parser.add_argument('--custshell', metavar="\\x00...", help='Custom shellcode string to use.')
        parser.add_argument('--update', action='store_true', help='Update the Veil framework.')
        parser.add_argument('--clean', action='store_true', help='Clean out payload folders.')
        parser.add_argument('--overwrite', action='store_true', help='Overwrite payload/source output files if they already exist.')
        parser.add_argument('--rpc', action='store_true', help='Run Veil-Evasion as an RPC server.')
        parser.add_argument('--rpcshutdown', action='store_true', help='Shutdown a running Veil-Evasion RPC server.')
        args = parser.parse_args()

        # start up the RPC server
        if args.rpc:
            runRPC()
            sys.exit()

        # shutdown the RPC server
        if args.rpcshutdown:
            shutdownRPC()
            sys.exit()

        # Print main title
        messages.title()

        # instantiate the main controller object
        controller = controller.Controller(oneRun=False)

        # call the update functionality for Veil and then exit
        if args.update:
            controller.UpdateVeil(interactive=False)
            sys.exit()

        # call the payload folder cleaning for Veil and then exit
        if args.clean:
            controller.CleanPayloads(interactive=False)
            sys.exit()

        # use interactive menu if a payload isn't specified
        if not args.p:
            controller.MainMenu()
            sys.exit()

        # list languages available if "-p" is present but no payload specified
        elif args.p == "list":
            controller.ListPayloads()
            sys.exit()
        
        # pull out any required options from the command line and
        # build the proper dictionary so we can set the payload manually
        options = {}
        if args.c:
            options['required_options'] = {}
            for option in args.c:
                name,value = option.split("=")
                options['required_options'][name] = [value, ""]

        # pull out any msfvenom shellcode specification and msfvenom options
        if args.msfpayload:
            if args.msfoptions:
                options['msfvenom'] = [args.msfpayload, args.msfoptions]
            else:
                options['msfvenom'] = [args.msfpayload, None]

        # manually set the payload in the controller object
        controller.SetPayload(args.p, options)

        # generate the payload code
        code = controller.GeneratePayload()

        # write out the payload code to the proper output file
        outName = controller.OutputMenu(controller.payload, code, showTitle=False, interactive=False, overwrite=args.overwrite, OutputBaseChoice=args.o)

    # Catch ctrl + c interrupts from the user
    except KeyboardInterrupt:
        print helpers.color("\n\n [!] Exiting...\n", warning=True)

