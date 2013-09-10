#!/usr/bin/env python
#-*- coding:utf-8 -*-

import time
import commands
import wx

class App(wx.App):
    def __init__(self, redirect=True, filename=None):
        wx.App.__init__(self, redirect, filename)
    
    def OnInit(self):
        dlg = wx.MessageDialog(None,
                          '- WARNING - \nDisconnected to vpnserver',
                          'OpenVPN Status',
                           wx.OK | wx.ICON_WARNING)
        result = dlg.ShowModal()
        dlg.Destroy()
        return True

while True:
    time.sleep(30)
    (status, output) = commands.getstatusoutput('route -n | grep -q 10.20.')
    if status != 0:
        app = App(False, "Output")
        app.MainLoop()
        exit()
