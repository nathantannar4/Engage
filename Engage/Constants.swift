//
//  Constants.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-08.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import NTUIKit

/* Installation */
let PF_INSTALLATION_CLASS_NAME			= "_Installation"           //	Class name
let PF_INSTALLATION_OBJECTID			= "objectId"				//	String
let PF_INSTALLATION_USER				= "user"					//	Pointer to User Class

/* User */
let PF_USER_EXTENSION                   = "user"
let PF_USER_CLASS_NAME					= "_User"                   //	Class name
let PF_USER_OBJECTID					= "objectId"				//	String
let PF_USER_USERNAME					= "username"				//	String
let PF_USER_PASSWORD					= "password"				//	String
let PF_USER_EMAIL						= "email"                   //	String
let PF_USER_FULLNAME					= "fullname"				//	String
let PF_USER_FULLNAME_LOWER				= "fullname_lower"          //	String
let PF_USER_PICTURE						= "picture"                 //	File
let PF_USER_PHONE                       = "phone"                   //	String
let PF_USER_ENGAGEMENTS                 = "engagements"             //	Array
let PF_USER_BLOCKED                     = "blocked_users"           //  Array
let PF_USER_EXTENSION_CLASSNAME         = "User"
let PF_USER_COVER                       = "coverPicture"
let PF_USER_TEAM                        = "subgroup"
let PF_USER_BIO                        = "bio"


/* Posts */
let PF_POST_CLASSNAME                   = "_Posts"
let PF_POST_CREATED_AT                  = "createdAt"
let PF_POST_INFO                        = "info"
let PF_POST_COMMENTS                    = "comments"
let PF_POST_COMMENT_DATES               = "commentsDate"
let PF_POST_COMMENT_USERS               = "commentsUser"
let PF_POST_REPLIES                     = "replies"
let PF_POST_USER                        = "user"
let PF_POST_HAS_IMAGE                   = "hasImage"
let PF_POST_IMAGE                       = "image"
let PF_POST_TO_OBJECT                   = "toObject"
let PF_POST_TO_USER                     = "toUser"
let PF_POST_LIKES                       = "likes"

let PF_FLAGGED_POST_CLASSNAME           = "_Flagged_Posts"
let PF_FLAGGED_POST_POST                = "post"
let PF_FLAGGED_POST_REASON              = "reason"
let PF_FLAGGED_POST_USER                = "user"

/* Engagements */
let PF_ENGAGEMENTS_CLASS_NAME           = "Engagements"             //  Class name
let PF_ENGAGEMENTS_NAME                 = "name"                    //  String
let PF_ENGAGEMENTS_LOWERCASE_NAME       = "lowercase_name"          //  String
let PF_ENGAGEMENTS_MEMBERS              = "members"                 //  Array
let PF_ENGAGEMENTS_MEMBER_COUNT         = "memberCount"             //  Number
let PF_ENGAGEMENTS_HIDDEN               = "hidden"                  //  Bool
let PF_ENGAGEMENTS_PASSWORD             = "password"                //  String
let PF_ENGAGEMENTS_ADMINS               = "admins"                  //  Array
let PF_ENGAGEMENTS_INFO                 = "info"                    //  String
let PF_ENGAGEMENTS_COVER_PHOTO          = "coverphoto"              //  File
let PF_ENGAGEMENTS_LOGO                 = "logo"                    //  File
let PF_ENGAGEMENTS_PROFILE_FIELDS       = "profile_fields"          //  Array
let PF_ENGAGEMENTS_PHONE                = "phone"                   //  String
let PF_ENGAGEMENTS_ADDRESS              = "address"                 //  String
let PF_ENGAGEMENTS_EMAIL                = "email"                   //  String
let PF_ENGAGEMENTS_URL                  = "url"                     //  String
let PF_ENGAGEMENTS_POSITIONS            = "positions"               //  Array
let PF_ENGAGEMENTS_SUBGROUP_NAME        = "subGroupName"            //  Array
let PF_ENGAGEMENT_COLOR                 = "color"
let PF_ENGAGEMENT_SPONSOR               = "sponsor"

/* Engagement Sub Groups */
let PF_SUBGROUP_CLASS_NAME              = "_SubGroup"                //  Class Name
let PF_SUBGROUP_NAME                    = "name"                    //  String
let PF_SUBGROUP_LOWERCASE_NAME          = "lowercase_name"          //  String
let PF_SUBGROUP_MEMBERS                 = "members"                 //  Array
let PF_SUBGROUP_COVER_PHOTO             = "coverphoto"              //  File
let PF_SUBGROUP_INFO                    = "info"                    //  String
let PF_SUBGROUP_ADMINS                  = "admins"                  //  Array
let PF_SUBGROUP_PHONE                   = "phone"                   //  String
let PF_SUBGROUP_ADDRESS                 = "address"                 //  String
let PF_SUBGROUP_EMAIL                   = "email"                   //  String
let PF_SUBGROUP_URL                     = "url"                     //  String
let PF_SUBGROUP_POSITIONS               = "positions"               //  Array
let PF_SUBGROUP_IS_SPONSOR              = "isSponsor"

/* Conference */
let PF_CONFERENCE_DELEGATES             = "delegates"               //  String
let PF_CONFERENCE_ORGANIZERS            = "organizers"              //  String
let PF_CONFERENCE_INFO                  = "info"                    //  String
let PF_CONFERENCE_NAME                  = "name"                    //  String
let PF_CONFERENCE_PASSWORD              = "password"                //  String
let PF_CONFERENCE_COVER_PHOTO           = "coverphoto"              //  File
let PF_CONFERENCE_HOST_SCHOOL           = "hostschool"              //  String
let PF_CONFERENCE_YEAR                  = "year"                    //  String
let PF_CONFERENCE_LOCATION              = "location"                //  String
let PF_CONFERENCE_URL                   = "url"                     //  String
let PF_CONFERENCE_POSITIONS             = "positions"               //  Array
let PF_CONFERENCE_SPONSORS              = "sponsors"                //  Array
let PF_CONFERENCE_START                 = "start"                //  Array
let PF_CONFERENCE_END                   = "end"                //  Array

/* Events */
let PF_EVENT_CLASS_NAME                 = "_Events"                  //  Class name
let PF_EVENT_NAME                       = "name"                   //  String
let PF_EVENT_LOCATION                   = "location"
let PF_EVENT_INFO                       = "info"
let PF_EVENT_URL                        = "url"
let PF_EVENT_START                      = "start"
let PF_EVENT_END                        = "end"
let PF_EVENT_ORGANIZER                  = "organizer"
let PF_EVENT_INVITES                    = "invites"
let PF_EVENT_ACCEPTED                   = "accepted"
let PF_EVENT_DECLINED                   = "declined"
let PF_EVENT_LONGITUDE                  = "longitude"
let PF_EVENT_LATITUDE                   = "latitude"
let PF_EVENT_PRIVATE                    = "private"
let PF_EVENT_IMAGE                      = "image"

/* Channel */
let PF_CHANNEL_CLASS_NAME               = "_Channels"
let PF_CHANNEL_NAME                     = "name"
let PF_CHANNEL_IMAGE                    = "image"
let PF_CHANNEL_MEMBERS                  = "members"
let PF_CHANNEL_ADMINS                   = "admins"
let PF_CHANNEL_PRIVATE                  = "private"
let PF_CHANNEL_UPDATED_AT               = "updatedAt"
let PF_CHANNEL_OBJECT_ID                = "objectId"

/* Messages*/
let PF_MESSAGE_CLASS_NAME				= "_Messages"				//	Class name
let PF_MESSAGE_USER                     = "user"					//	Pointer to User Class
let PF_MESSAGE_CHANNEL                  = "channel"                 //	String
let PF_MESSAGE_FILE                     = "file"
let PF_MESSAGE_TEXT                     = "text"
let PF_MESSAGE_CREATED_AT               = "createdAt"

/* Chat */
let PF_CHAT_CLASS_NAME					= "_Chat"					//	Class name
let PF_CHAT_USER						= "user"					//	Pointer to User Class
let PF_CHAT_GROUPID						= "groupId"                 //	String
let PF_CHAT_TEXT						= "text"					//	String
let PF_CHAT_PICTURE						= "picture"                 //	File
let PF_CHAT_VIDEO						= "video"                   //	File
let PF_CHAT_CREATEDAT					= "createdAt"               //	Date

/* Groups */
let PF_GROUPS_CLASS_NAME				= "_Groups"                  //	Class name
let PF_GROUPS_NAME                      = "name"					//	String


/* Notification */
let NOTIFICATION_APP_STARTED			= "NCAppStarted"
let NOTIFICATION_USER_LOGGED_IN			= "NCUserLoggedIn"
let NOTIFICATION_USER_LOGGED_OUT		= "NCUserLoggedOut"
