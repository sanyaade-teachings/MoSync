/*
Copyright (C) 2011 MoSync AB

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License,
version 2, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.
*/

/*
 * FacebookDemoMoblet.h
 */

#ifndef FACEBOOKDEMOMOBLET_H_
#define FACEBOOKDEMOMOBLET_H_

#include <ma.h>
#include <mavsprintf.h>
#include <MAUtil/Moblet.h>
#include <MAUtil/String.h>
#include <IX_WIDGET.h>

#include "Facebook/FacebookManager.h"
#include "GUI/ListScreen.h"
#include "GUI/FacebookLoginScreen.h"
#include "GUI/MainScreen.h"


/**
 * Class that creates the main screen and handles key press events
 */
class FacebookDemoMoblet : public MAUtil::Moblet, public NativeUI::WebViewListener
{
public:
	/**
	 * The constructor creates the user interface and the FacebookManager
	 */
	FacebookDemoMoblet(const MAUtil::String &appId);

	virtual void webViewHookInvoked( NativeUI::WebView* webView, int hookType,
			MAHandle urlData);

	/**
	 * WebViewListener overrides
	 */
	virtual void webViewContentLoading(
			NativeUI::WebView* webView,
			const int webViewState) {}

	/**
	 * destructor.
	 */
	~FacebookDemoMoblet();

	/**
	 * This method is called when the application is closed.
	 */
	void closeEvent() GCCATTRIB(noreturn);
private:
	void login();

	/**
	 * creates the FacebookManager object, that handles the requests to Facebook, retrieving data and publishing
	 */
	void initializeFacebook(const MAUtil::String &appId);

	/**
	 * creates the GUI
	 */
	void createGUI();


	MAUtil::String extractAccessToken(const char *newurl);

private:
	/**
	 * creation of buttons for the main menu
	 */


	/**
	 * Creates a button and adds it to the main menu
	 * Adds on the button a command that sends the publish request to Facebook
	 */
	void addLinkOnWall(FacebookDemoGUI::ListScreen *menu);
	void addPostOnWall(FacebookDemoGUI::ListScreen *menu);
	void addStatusMessageOnWall(FacebookDemoGUI::ListScreen *menu);

	/**
	 * Creates a button and adds it to the main menu
	 * Adds on the button a command that sends the connection request to Facebook
	 */
	void addActivitiesButton(FacebookDemoGUI::ListScreen *menu);
	void addAlbumsButton(FacebookDemoGUI::ListScreen *menu);
	void addBooksButton(FacebookDemoGUI::ListScreen *menu);
	void addCheckinsButton(FacebookDemoGUI::ListScreen *menu);
	void addFeedButton(FacebookDemoGUI::ListScreen *menu);
	void addHomeButton(FacebookDemoGUI::ListScreen *menu);
	void addInterestsButton(FacebookDemoGUI::ListScreen *menu);
	void addLikesButton(FacebookDemoGUI::ListScreen *menu);
	void addLinksButton(FacebookDemoGUI::ListScreen *menu);
	void addMusicButton(FacebookDemoGUI::ListScreen *menu);
	void addPhotosButton(FacebookDemoGUI::ListScreen *menu);
	void addPictureButton(FacebookDemoGUI::ListScreen *menu);
	void addPostsButton(FacebookDemoGUI::ListScreen *menu);
	void addTelevisionButton(FacebookDemoGUI::ListScreen *menu);
	void addEventsButton(FacebookDemoGUI::ListScreen *menu);
	void addFriendsButton(FacebookDemoGUI::ListScreen *menu);
	void addFriendListsButton(FacebookDemoGUI::ListScreen *menu);
	void addNotesButton(FacebookDemoGUI::ListScreen *menu);
	void addStatusMessagesButton(FacebookDemoGUI::ListScreen *menu);

private:
	/**
	 * FacebookManager object: handles the requests to Facebook, retrieving data and publishing
	 */
	FacebookManager							*mFacebookManager;
	FacebookDemoGUI::MainScreen				*mMainScreen;
	FacebookDemoGUI::FacebookLoginScreen 	*mLoginScreen;
};

#endif /* FACEBOOKDEMOMOBLET_H_ */
