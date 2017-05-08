<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*,java.net.*,java.io.*,org.json.simple.*,org.json.simple.parser.*" %>
<html>
    <head></head>
    <body>
        <%
           String userEmail = request.getParameter("user");
           PrintWriter writer = response.getWriter();
           if(userEmail != null && userEmail.endsWith("@sungardas.com"))
           {
             //
             //
             // Make a POST request 
             //   - To https://uat-sso.sungardas.com/api/v4/pingid/user/authenticate
             //   - Set Content-Type header to application/json
             //   - Send this payload: 
             //     { "email":"user@example.com", "applicationName":"MyApp" }
             //   - Wait for response. It will return a 200, 403 or 501
             //
             HttpURLConnection conn = null;
             try 
             {
                 StringBuilder sBuffer = new StringBuilder();
                 sBuffer.append("{")
                        .append(  "\"email\":\"").append(userEmail).append("\",")
                        .append(  "\"applicationName\":\"ChittaBSandboxApp\"")
                        .append("}");

                 URL url = new URL("https://uat-sso.sungardas.com/api/v4/pingid/user/authenticate");
                 conn = (HttpURLConnection)url.openConnection();
                 conn.setRequestMethod("POST");
                 conn.addRequestProperty("Content-Type", "application/json");
                 conn.addRequestProperty("Accept", "*/*");

                 conn.setDoOutput(true);
                 OutputStreamWriter outt = new OutputStreamWriter(conn.getOutputStream(), "UTF-8");
                 outt.write(sBuffer.toString());
                 outt.flush();
                 outt.close();

                 if (conn.getResponseCode() == 200) 
                 {
                    JSONParser jsonParser = new JSONParser();
                    JSONObject jsonObj 
                      = (JSONObject)jsonParser.parse(
                                         new InputStreamReader(conn.getInputStream()));

                    writer.write("You have sucessfully authenticated from an "
                                 + jsonObj.get("deviceType") + " " 
                                 + jsonObj.get("deviceOSVersion") + " device");
                    if(jsonObj.containsKey("gpsLocation"))
                    {
                        JSONObject location = (JSONObject)jsonObj.get("gpsLocation");
                        writer.write(" at GPS coordinate (" 
                                     + location.get("latitude") + ", "
                                     + location.get("longitude") + ")<br/>");
                        writer.write("<i>(I have no freakin' idea where that is BTW)</i>");
                    }
                    writer.write("<hr/>");
                    //writer.write(jsonObj.toString());
                    writer.flush();

                 } 
                 else 
                 {
                    writer.write("<br/><h1>2nd factor verification failed for "+ userEmail+ "</h1>");
                    writer.flush();
                    return;
                 }
              } 
              catch (Exception ex) 
              {
                 writer.write("<br/><h1>Exception validating 2nd factor for "+ userEmail+ "</h1>");
                 writer.flush();
                 return;
              }
              finally
              {
                  if(conn != null) conn.disconnect();
              }

           }

           writer.write("<br/><h1>User "+ userEmail+ " has been fully authenticated.</h1>");
           writer.write("<br/>");
           Map<String, ArrayList> attrs 
             = (Map<String, ArrayList>)session.getAttribute("userprofile");
           for(String attr : attrs.keySet())
           {
                writer.write("<br/>   *** " + attr + ": " + attrs.get(attr));
           }
           writer.flush();
        %>
    </body>
</html>
