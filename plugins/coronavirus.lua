--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local coronavirus = {}
local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')

function coronavirus:init()
    coronavirus.commands = mattata.commands(self.info.username):command('coronavirus'):command('corona'):command('covid19'):command('covid').table
    coronavirus.help = '/coronavirus [country]. Returns the global COVID-19 statistics. Optionally, a country may be specified by its country code or name. Aliases: /corona, /covid19, /covid.'
    coronavirus.url = 'https://api.covid19api.com/summary'
end


function coronavirus.on_message(_, message, _, language)
    local jstr, res = https.request(coronavirus.url)
    if res ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    local jdat = json.decode(jstr)
    if not jdat.Global and not jdat.Countries then
        return mattata.send_reply(message, language.errors.results)
    end
    local input = mattata.input(message.text)
    local found_match, country_position, output = false
    if jdat.Global and (not input or (input:lower() == 'global' or input:lower() == 'world')) then
        output = language['coronavirus']['1']
        local country_name = 'Everywhere'
        local new_confirmed = mattata.comma_value(jdat.Global.NewConfirmed)
        local total_confirmed = mattata.comma_value(jdat.Global.TotalConfirmed)
        local new_deaths = mattata.comma_value(jdat.Global.NewDeaths)
        local total_deaths = mattata.comma_value(jdat.Global.TotalDeaths)
        local new_recovered = mattata.comma_value(jdat.Global.NewRecovered)
        local total_recovered = mattata.comma_value(jdat.Global.TotalRecovered)
        output = string.format(output, country_name, new_confirmed, total_confirmed, new_deaths, total_deaths, new_recovered, total_recovered)
    elseif input and jdat.Countries then
        for k, v in pairs(jdat.Countries) do
            if input:len() == 2 then
                input = input:lower() == 'uk' and 'gb' or input:lower()
                if input == v.CountryCode:lower() then
                    found_match, country_position = true, k
                end
            else
                if v.Country:lower():match(input:lower()) then
                    found_match, country_position = true, k
                end
            end
        end
    end
    if found_match then
        output = language['coronavirus']['1']
        local country_name = jdat.Countries[country_position].Country
        local new_confirmed = mattata.comma_value(jdat.Countries[country_position].NewConfirmed)
        local total_confirmed = mattata.comma_value(jdat.Countries[country_position].TotalConfirmed)
        local new_deaths = mattata.comma_value(jdat.Countries[country_position].NewDeaths)
        local total_deaths = mattata.comma_value(jdat.Countries[country_position].TotalDeaths)
        local new_recovered = mattata.comma_value(jdat.Countries[country_position].NewRecovered)
        local total_recovered = mattata.comma_value(jdat.Countries[country_position].TotalRecovered)
        output = string.format(output, country_name, new_confirmed, total_confirmed, new_deaths, total_deaths, new_recovered, total_recovered)
    end
    output = output or language.errors.results
    return mattata.send_reply(message, output, 'markdown')
end

return coronavirus