package com.example.map_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class LiveTrackingWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Tracking Status Toggle
                val isTracking = widgetData.getString("widget_tracking_active", "false") == "true"
                val trackingMessage = widgetData.getString(
                    "widget_message",
                    context.getString(R.string.widget_tracking_default)
                )
                
                if (isTracking) {
                    setViewVisibility(R.id.widget_search, android.view.View.GONE)
                    setViewVisibility(R.id.widget_tracking_banner, android.view.View.VISIBLE)
                    setTextViewText(R.id.widget_tracking_text, trackingMessage)
                } else {
                    setViewVisibility(R.id.widget_search, android.view.View.VISIBLE)
                    setViewVisibility(R.id.widget_tracking_banner, android.view.View.GONE)
                }

                // Binding intents for deep links
                val searchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mapapp://search")
                )
                setOnClickPendingIntent(R.id.widget_search, searchIntent)
                // Also make the tracking banner clickable to go to tracking page (can reuse searchIntent or map intent)
                setOnClickPendingIntent(R.id.widget_tracking_banner, searchIntent)

                val joinRoomIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mapapp://join_room")
                )
                setOnClickPendingIntent(R.id.btn_join_room, joinRoomIntent)

                val communityIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mapapp://community")
                )
                setOnClickPendingIntent(R.id.btn_community, communityIntent)

                val albumIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mapapp://album")
                )
                setOnClickPendingIntent(R.id.btn_album, albumIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
