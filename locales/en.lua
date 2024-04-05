local Translations = {

    client = {
        lang_1 = 'Open ',
        lang_2 = 'Bank Closed',
        lang_3 = 'come back after ',
        lang_4 = 'am',
    },

    server = {
        lang_1 = 'Invalid Amount',
        lang_2 = 'Insufficient Funds',
        lang_3 = 'Money Clip Used',
        lang_4 = 'You\'ve got $',
        lang_5 = ' cash from this Money Clip!',
        lang_6 = 'Make Money Clip',
        lang_7 = 'How much money do you want convert?',
        lang_8 = 'please enter the correct amount!',
        lang_9 = 'Money Clip Converted',
        lang_10 = 'You\'ve just converted $',
        lang_11 = ' cash into a Money Clip!',
        lang_12 = 'Blood Money Clip Used',
        lang_13 = ' bloodmoney from this Blood Money Clip!',
        lang_14 = 'Make Blood Money Clip',
        lang_15 = 'How much blood money do you want convert?',
        lang_16 = 'Blood Money Clip Converted',
        lang_17 = ' bloodmoney into a Money Clip!',
    },

}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

-- Lang:t('client.lang_1')
-- Lang:t('server.lang_1')
