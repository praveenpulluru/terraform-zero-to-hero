Doing a Vehicle reservation books the entire time in the calendar.
As is, for example, every car booking I make completely fills the whole day in my calendar and people trying to set up meetings think I am not available. Events cannot be deleted from calendar post-booking either, as that results in cancellation in Book a Space. Another problem is this decreases readability of the calendar free slots for me as well.

the Google cal GUI has the capability to mark a reservation as free or busy. 

Per Google Gemini, there is an API to manage the free/busy status of events in Google Calendar. You can achieve this through the Google Calendar API, specifically when you create or update an event.
When inserting or updating an event resource, you can use the transparency property to indicate whether an event should block time on a calendar.
Here's how it works:

transparency: This property of an event determines if the event appears to others as blocking time (busy) or available (free).
Setting transparency to "opaque" (which is the default) indicates that the event makes the time span unavailable (busy).
Setting transparency to "transparent" indicates that the event makes the time span available (free).
You can set this property when you:
Create a new event using the events.insert method.
Update an existing event using the events.update or events.patch methods.
Here's a simplified example of how you might set the transparency property when creating an event using the Google Calendar API (in JSON format for the request body):
{
"summary": "Optional Meeting",
"start": { "dateTime": "2025-05-05T10:00:00-07:00" }
,
"end":

{ "dateTime": "2025-05-05T11:00:00-07:00" }
,
"transparency": "transparent"
}

In this example, even though the event exists in the calendar, it will not appear as "busy" to others checking your availability.
How to use the API:
To use the Google Calendar API, you would typically follow these steps:

Set up a Google Cloud Project: If you don't already have one, you'll need to create a project in the Google Cloud Console.
Enable the Google Calendar API: Within your project, enable the Google Calendar API.
Configure OAuth 2.0 credentials: You'll need to set up OAuth 2.0 credentials to authorize your application to access Google Calendar on behalf of users.
Use a client library or make HTTP requests: Google provides client libraries for various programming languages (like Python, Java, Node.js, etc.) that simplify interaction with the API. Alternatively, you can make direct HTTP requests to the API endpoints.
Regarding Free/Busy Queries:
It's important to note that there is also a separate API endpoint, freeBusy.query, which allows you to retrieve the free/busy information for a set of calendars within a specified time range. This is useful for checking the availability of others when scheduling meetings, but it's not used to set the free/busy status of an event. The free/busy status of an event is set when the event itself is created or updated using the transparency property.




package com.verizon.vzreserve.controller;

import com.verizon.vzreserve.dao.entity.User;
import com.verizon.vzreserve.service.UserService;
import com.verizon.vzreserve.utils.GeneralUtility;
import jakarta.validation.Valid;

import com.verizon.vzreserve.dto.*;
import com.verizon.vzreserve.service.MRReservationService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import com.verizon.vzreserve.dao.entity.BookingStatus;
import com.verizon.vzreserve.exception.VzException;
import com.verizon.vzreserve.exception.VzValidationException;
import com.verizon.vzreserve.service.DeskReservationService;
import com.verizon.vzreserve.service.GoogleReservationService;
import com.verizon.vzreserve.utils.VzConstants;
import com.verizon.vzreserve.utils.VzValidationUtility;

@RestController
@RequestMapping("/api/reservation")
public class GoogleReservationController {

	@Autowired
	private GoogleReservationService googleReservationService;

	@Autowired
	private DeskReservationService deskReservationService;

	@Autowired
	private MRReservationService mrReservationService;

	@Autowired
	private UserService userService;

	@CrossOrigin
	@PostMapping
	public GoogleStatusResponseReservationDto makeReservation(
			@RequestBody @Valid ReservationCreationRequestDto reservationDto) {
		return new GoogleStatusResponseReservationDto(googleReservationService.makeGoogleReservation(reservationDto, false, VzConstants.BAS_USER_EVENT, null, null));
	}
	
	@CrossOrigin
	@PostMapping(value = "/qr")
	public GoogleStatusResponseReservationDto makeReservationAndCheckIn(
			@RequestBody @Valid ReservationCreationRequestDto reservationDto) {
		return new GoogleStatusResponseReservationDto(googleReservationService.makeGoogleReservation(reservationDto, true, VzConstants.BAS_USER_EVENT, null, null));
	}

	@CrossOrigin
	@PostMapping(value = "/remove/{eventId}")
	public CallStatusDto cancelReservation(@PathVariable String eventId, @RequestBody @Valid UserDto user) throws VzException {
		return googleReservationService.cancelReservation(user, eventId, BookingStatus.STATUS_TYPE_CANCELLED_USER, false, false);
	}

	@CrossOrigin
	@PostMapping(value = "/cancel", produces = MediaType.APPLICATION_JSON_VALUE)
	public CallStatusDto cancelEvent(@RequestParam(required = false) String reservationId,
			@RequestParam(required = false) String bookingId,
			@RequestParam(required = false) String appCode,
			@RequestParam(required = false, defaultValue = VzConstants.RESERVATION_TYPE_GOOGLE) String reservationType,
			@Valid @RequestBody UserDto userDto) {
		CallStatusDto cancelResponse;
		if (VzConstants.RESERVATION_TYPE_DESK.equals(reservationType) && StringUtils.isNotBlank(reservationId)
				&& StringUtils.isNumeric(reservationId)) {
			cancelResponse = deskReservationService.validateAndCancelDesk(reservationId, bookingId, userDto, false);
		} else if (VzConstants.RESERVATION_TYPE_GOOGLE.equals(reservationType)
				&& StringUtils.isNotBlank(reservationId)) {
			UserDto hostDto = null;
			if(userDto != null && !GeneralUtility.isGoogleResource(userDto.getEmail())) {
				User user = userService.findByEnterpriseIdOrEmail(userDto.getEnterpriseId(), userDto.getEmail());
				hostDto = new UserDto(user);
			} else{
				hostDto = userDto;
			}
			cancelResponse = googleReservationService.endOrCancelReservation(reservationId, hostDto);
		} else {
			cancelResponse = new CallStatusDto(false,
					"A valid reservation details is required to perform the cancellation");
		}
		return cancelResponse;
	}

	@CrossOrigin
	@PostMapping(value = "/cancel/multiple", produces = MediaType.APPLICATION_JSON_VALUE)
	public CallStatusDto cancelMultipleReservations(@RequestParam(required = false) String reservationId,
									 @RequestParam(required = false) String bookingId,
									 @RequestParam(required = false) String appCode,
									 @RequestParam(required = false, defaultValue = VzConstants.RESERVATION_TYPE_GOOGLE) String reservationType,
									 @Valid @RequestBody UserDto userDto) {
		return deskReservationService.cancelMutipleReservations(reservationId, bookingId, reservationType, appCode, userDto);
	}

	public void validateRequest(ReservationCreationRequestDto reservationDto) throws VzValidationException {
		VzValidationUtility.validateSchedule(reservationDto.getSchedule());
		VzValidationUtility.validateUser(reservationDto.getHost());
		VzValidationUtility.validateUser(reservationDto.getCreator());
	}
	
	@CrossOrigin
	@PostMapping(value = "/checkin")
	public ApiResponse<Void> doCheckIn(@RequestBody VzGoogleReservationDto checkInRequest) throws VzException {
		return googleReservationService.doCheckIn(checkInRequest, false);
	}

	@CrossOrigin
	@PostMapping(value = "/{id}")
	public VzReservationDto getReservationData(
			@PathVariable(value = "id", required = true) String eventId,
			@RequestBody @Valid UserDto user
	) throws VzException {
		return googleReservationService.getUserEventById(user, eventId);
	}

	@CrossOrigin
	@PostMapping(value = "/override/ltb")
	public String overrideResWithLtb(
			@RequestBody @Valid CreateLTBREquestDto request
	) throws VzException {
		mrReservationService.createLTB(request);
		return "Triggered Successfully";
	}
}


package com.verizon.vzreserve.service;

import com.google.api.services.calendar.model.Event;
import com.google.api.services.calendar.model.EventAttendee;
import com.verizon.vzreserve.cisco.service.SmhubService;
import com.verizon.vzreserve.config.systemproperty.SystemPropertyDto;
import com.verizon.vzreserve.config.systemproperty.SystemPropertyService;
import com.verizon.vzreserve.controller.exception.ResourceNotFoundException;
import com.verizon.vzreserve.dao.entity.*;
import com.verizon.vzreserve.dao.repository.BookingAuditRepository;
import com.verizon.vzreserve.dao.repository.ResourceRepository;
import com.verizon.vzreserve.dao.repository.UserRepository;
import com.verizon.vzreserve.dao.repository.VzGoogleReservationRepository;
import com.verizon.vzreserve.dto.*;
import com.verizon.vzreserve.dto.eventSupport.EventSupportDto;
import com.verizon.vzreserve.dto.eventSupport.HostDetailsDto;
import com.verizon.vzreserve.dto.eventSupport.ResourceDetailsDto;
import com.verizon.vzreserve.dto.model.GoogleStatusResponseReservation;
import com.verizon.vzreserve.dto.model.ScheduleHolder;
import com.verizon.vzreserve.dto.model.StatusResponse;
import com.verizon.vzreserve.dto.model.StatusResponseReservation;
import com.verizon.vzreserve.enums.GoogleEventStatus;
import com.verizon.vzreserve.enums.TemplateType;
import com.verizon.vzreserve.exception.VzException;
import com.verizon.vzreserve.exception.VzReservationNotFoundException;
import com.verizon.vzreserve.exception.VzValidationException;
import com.verizon.vzreserve.gsuite.service.GsuiteReservationService;
import com.verizon.vzreserve.gsuite.utils.AuthenticationCredentialCalendar;
import com.verizon.vzreserve.integration.service.DataStorageService;
import com.verizon.vzreserve.integration.service.SmarthubDataProviderService;
import com.verizon.vzreserve.utils.GeneralUtility;
import com.verizon.vzreserve.utils.VzConstants;
import com.verizon.vzreserve.utils.VzValidationUtility;
import org.apache.commons.beanutils.BeanUtils;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.collections4.MapUtils;
import org.apache.commons.lang3.StringUtils;
import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.joda.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.lang.reflect.InvocationTargetException;
import java.util.*;
import java.util.Map.Entry;
import java.util.stream.Collectors;

@Service
public class GoogleReservationService {
	
	private final Logger log = LoggerFactory.getLogger(this.getClass());

    @Autowired
    private ResourceRepository resourceRepository;

    @Autowired
    private VzGoogleReservationRepository vzReservationRepository;

    @Autowired
    private GsuiteReservationService gsuiteReservationService;

    @Lazy
    @Autowired
    private UserService userService;
    
	@Autowired
	private EmailService emailService;
	
	@Autowired
	private SystemPropertyService systemPropertyService;

	@Autowired
	private ClientsService clientsService;

	@Autowired
	private ScheduleProviderService scheduleProviderService;

	@Autowired
	UserRepository userRepository;

	@Autowired
	private BookingAuditRepository bookingAuditRepository;

    @Autowired
	private SmarthubDataProviderService smarthubDataProviderService;

	@Autowired
	private SmhubService smhubService;

	@Autowired
	private DataStorageService dataStorageService;

    public GoogleStatusResponseReservation makeGoogleReservation(ReservationCreationRequestDto reserveCreateDto, boolean autoCheckIn, String eventFrom, String version, String platform) {
        GoogleStatusResponseReservation creationStatusResponse = new GoogleStatusResponseReservation();

        User host = new User();
        User creator = new User();

		if(Boolean.TRUE.equals(reserveCreateDto.getLongTermBooking())) {
			creator.setEmail(AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL);
			creator.setGoogleMigrated(false);
//			creator.setName(creatorDto.getName());
			host = userService.findOrAdd(reserveCreateDto.getHost());
		}else {
			host = userService.findOrAdd(reserveCreateDto.getHost());
			creator = userService.findOrAdd(reserveCreateDto.getCreator());
		}

        if(eventFrom == VzConstants.FINDR_USER_EVENT) {
        	UserDto user = new UserDto();
        	user.setBuildingCode(host.getBuildingCode());
        	user.setBusinessGroup(host.getBusinessGroup());
        	user.setCompany(host.getCompany());
        	user.setEmail(host.getEmail());
        	user.setEnabled(host.getEnabled());
        	user.setEnterpriseId(host.getEnterpriseId());
        	user.setGoogleMigrated(host.isGoogleMigrated());
        	user.setHrlob(host.getHrlob());;
        	user.setId(host.getId());
        	user.setName(host.getName());
        	reserveCreateDto.setHost(user);
        	reserveCreateDto.setCreator(user);
        }
        VzGoogleReservation vzReservation = new VzGoogleReservation();

        vzReservation.setHost(host);
        vzReservation.setCreator(creator);
        vzReservation.setTitle(reserveCreateDto.getTitle());
        vzReservation.setRecurrenceRule(reserveCreateDto.getRecurrenceRule());
        try {
            Set<Resource> resources = resourceRepository.findResourcesByIds(reserveCreateDto.getResources());

			if(UserService.isOutsideDomainUser(reserveCreateDto.getCreator().getEmail())){
				if (!resources.isEmpty() && isRestrictedRoom(resources)) {
					log.error("Unable to Make Reservation due to one or more Restricted Rooms present");

					for (Resource resource : resources) {
						creationStatusResponse.addFailedBooking(new VzGoogleBooking(resource,
								new Schedule(scheduleProviderService.prepareSchedule(reserveCreateDto.getSchedule()))));
					}
					creationStatusResponse.determineStatus();
					if(eventFrom == VzConstants.FINDR_USER_EVENT){
						creationStatusResponse.setMessage("Restricted Room booking not allowed!");
					} else {
						creationStatusResponse.setMessage("Unable to Make Reservation due to one or more Restricted Rooms present");
					}
					return creationStatusResponse;
				}
			}

            if (resources.isEmpty()) {
                return new GoogleStatusResponseReservation(StatusResponseReservation.FAILED);
            } else {
                creationStatusResponse = gsuiteReservationService.makeReservation(reserveCreateDto, resources, autoCheckIn, eventFrom);
                vzReservation.setGSuiteId(creationStatusResponse.getSorId());
            }

            vzReservation.addBookings(creationStatusResponse.getSuccessBookings());
// Commenting the DB transaction as Google will be the single source of truth
//            if(vzReservation.getBookings() != null && !vzReservation.getBookings().isEmpty())
//            {
//                vzReservationRepository.saveAndFlush(vzReservation);
//            }

            creationStatusResponse.addFailedBookings(creationStatusResponse.getFailedBookings());
            creationStatusResponse.setSuccessBookings(vzReservation.getBookings());
            creationStatusResponse.setReservationId(vzReservation.getId());
            creationStatusResponse.setSorId(vzReservation.getGSuiteId());
            creationStatusResponse.determineStatus();
			if (StatusResponse.FAILED.equals(creationStatusResponse.getStatus())
					&& StringUtils.isNotBlank(creationStatusResponse.getSorId()))
				gsuiteReservationService.deleteReservation(
						(creator.isGoogleMigrated() && !UserService.isOutsideDomainUser(creator.getEmail()))
								? creator.getEmail()
								: AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL,
						creationStatusResponse.getSorId(), false);
			if (StatusResponse.SUCCESS_ALL.equals(creationStatusResponse.getStatus())
					|| StatusResponse.SUCCESS_PARTIAL.equals(creationStatusResponse.getStatus())) {
				notifyUsersOnConfirmation(host, resources, reserveCreateDto, creationStatusResponse);
				updateReservationInBookingAudit(creationStatusResponse, eventFrom, version, platform, Boolean.TRUE.equals(reserveCreateDto.getNotifyEventSupport()));
				if(Boolean.TRUE.equals(reserveCreateDto.getNotifyEventSupport())) {
					//send data to bas clients
					sendEntryRequestToClients(host, resources, creationStatusResponse, reserveCreateDto.getTitle());
				}else {
					if(!StringUtils.isEmpty(reserveCreateDto.getgSuiteId())){
						creationStatusResponse.getSuccessBookings().stream()
								.forEach(booking -> {
									sendDeleteReqtoClients(booking.getGSuiteId(), !StringUtils.isEmpty(reserveCreateDto.getRecurrenceRule()), false);
								});
					}
				}
			}
        } catch (Exception e) {
			log.error("Exception occured while creating the reservation. Details : {}", e.getMessage(), e);
        }
        log.info("booking={}", creationStatusResponse);
        return creationStatusResponse;
    }

	@Async
	public void updateReservationInBookingAudit(GoogleStatusResponseReservation creationStatusResponse, String source, String version, String platform, boolean hasEventSupport) {
		try {
			if (CollectionUtils.isNotEmpty(creationStatusResponse.getSuccessBookings())) {
				Resource resource = creationStatusResponse.getSuccessBookings().iterator().next().getResources().iterator().next();
				BookingAudit bookingAudit = new BookingAudit();
				bookingAudit.setBookingId(creationStatusResponse.getSorId());
				bookingAudit.setLocationId(resource.getLocation().getId());
				bookingAudit.setFloorId(resource.getFloor().getId());
				bookingAudit.setResourceGroupId(resource.getResourceGroup().getId());
				bookingAudit.setResourceTypeId(resource.getResourceType().getId());
				bookingAudit.setEventSupport(hasEventSupport);
				if (StringUtils.isNotEmpty(source))
					bookingAudit.setSource(source);
				if (StringUtils.isNotEmpty(version))
					bookingAudit.setVersion(version);
				if (StringUtils.isNotEmpty(platform))
					bookingAudit.setPlatform(platform);
				bookingAuditRepository.saveAndFlush(bookingAudit);
			}
		} catch (Exception e) {
			log.error("Exception occurred while updating the Google reservation in booking audit. Details : {}", e.getMessage(), e);
		}
	}

	public boolean isRestrictedRoom(Set<Resource> resources){
		String restrictedText = systemPropertyService.getPropertyValue("GSUITE_RESTRICTED_DESC");
		if(restrictedText != null && !restrictedText.isEmpty()){
			for(Resource res: resources){
				if(res.getDescription() != null && !res.getDescription().isEmpty() && res.getDescription().toLowerCase().contains(restrictedText.toLowerCase())){
					return true;
				}
			}
		}

		return false;
	}


	private void notifyUsersOnConfirmation(User host, Set<Resource> resources,
			ReservationCreationRequestDto reserveCreateDto, GoogleStatusResponseReservation creationStatusResponse) {
		try {
			ArrayList<UserDto> attendees = new ArrayList<>();
			String meetingTitle = reserveCreateDto.getTitle();
			String roomName = CollectionUtils.isNotEmpty(resources)
					? resources.stream().filter(Objects::nonNull).map(Resource::getName).filter(StringUtils::isNotBlank)
							.map(StringUtils::trim).collect(Collectors.joining("\n"))
					: "";
			// attendees.addAll(reserveCreateDto.getAttendees());
			// for (UserDto userDto2 : reserveCreateDto.getAttendees()) {
			// if (!userDto2.isGoogleMigrated()) {
			// attendees.add(userDto2);
			// }
			// }
			// send email to the host
			if(Boolean.TRUE.equals(reserveCreateDto.getLongTermBooking())) {
				emailService.sendLTBConfirmationMail(reserveCreateDto, creationStatusResponse.getSorId(),
						Arrays.asList(host.getEmail()),
						StringUtils.isNotBlank(reserveCreateDto.getgSuiteId()) ? TemplateType.GOOGLE_LTB_BOOKING_UPDATION
								: TemplateType.GOOGLE_LTB_BOOKING_CONFIRMATION,
						(!host.isGoogleMigrated() || UserService.isOutsideDomainUser(host.getEmail())) ? emailService.buildCalendarPart(
								new UserDto(host.getName(), host.getEmail()), // host
								reserveCreateDto.getSchedule().getStartTime(), reserveCreateDto.getSchedule().getEndTime(),
								roomName, meetingTitle, attendees, reserveCreateDto.getSchedule().getTimeZone()) : null);
			}else {
				emailService.sendConfirmationMailToHost(reserveCreateDto, creationStatusResponse.getSorId(),
						Arrays.asList(host.getEmail()),
						StringUtils.isNotBlank(reserveCreateDto.getgSuiteId()) ? TemplateType.GOOGLE_BOOKING_UPDATION
								: TemplateType.GOOGLE_BOOKING_CONFIRMATION,
						(!host.isGoogleMigrated() || UserService.isOutsideDomainUser(host.getEmail())) ? emailService.buildCalendarPart(
								new UserDto(host.getName(), host.getEmail()), // host
								reserveCreateDto.getSchedule().getStartTime(), reserveCreateDto.getSchedule().getEndTime(),
								roomName, meetingTitle, attendees, reserveCreateDto.getSchedule().getTimeZone()) : null);
			}
			// send email to concierge
			Map<String, List<String>> assetMap = reserveCreateDto.getAssetMap();
			sendMailToConcierge(reserveCreateDto, creationStatusResponse.getSorId(), resources, assetMap,
					TemplateType.GOOGLE_JAMBOARD_REQUEST);
			if (StringUtils.isNotEmpty(reserveCreateDto.getgSuiteId())) {
				assetMap = reserveCreateDto.getRemovedJamboards();
				sendMailToConcierge(reserveCreateDto, creationStatusResponse.getSorId(), resources, assetMap,
						TemplateType.GOOGLE_JAMBOARD_REMOVE);
			}
			// send email to event support
			if (Boolean.TRUE.equals(reserveCreateDto.getNotifyEventSupport())) {
				SystemPropertyDto eventSupportPropertyDto = systemPropertyService
						.getConfigByName(VzConstants.GSUITE_EVENT_SUPPORT_DL);
				if (eventSupportPropertyDto != null && StringUtils.isNotBlank(eventSupportPropertyDto.getValue()))
					emailService.sendConfirmationMailToEventSupport(host.getEmail(), eventSupportPropertyDto.getValue(),
							reserveCreateDto, creationStatusResponse.getSorId(),
							StringUtils.isNotBlank(reserveCreateDto.getgSuiteId())
									? TemplateType.EVENT_SUPPORT_GOOGLE_BOOKING_UPDATION
									: TemplateType.EVENT_SUPPORT_GOOGLE_BOOKING_CONFIRMATION,
							null);
			}
		} catch (Exception e) {
			log.error("Exception occured while notifying the users. Details : {}", e.getMessage(), e);
		}
	}

	public void sendEntryRequestToClients(User user, Set<Resource> resources, GoogleStatusResponseReservation creationStatusResponse, String title) {
		List<ResourceDetailsDto> resourceDetails = resources.stream().filter(Objects::nonNull).map(resource -> {
			return new ResourceDetailsDto(resource);
		}).collect(Collectors.toList());

		List<EventSupportDto> eventDetails = creationStatusResponse.getSuccessBookings().stream().filter(Objects::nonNull)
				.map(booking -> {
					return new EventSupportDto(booking.getGSuiteId(), new com.google.api.client.util.DateTime(booking.getSchedule().getStartTime()).toString(),
							new com.google.api.client.util.DateTime(booking.getSchedule().getEndTime()).toString(),
							new HostDetailsDto(user.getName(), user.getEmail(), user.getEnterpriseId(), user.getPhone()), resourceDetails, title, Instant.now().toString());
				}).collect(Collectors.toList());
		clientsService.sendEventDataToClients(eventDetails);
	}
    
	private void sendMailToConcierge(ReservationCreationRequestDto reserveCreateDto,
			String reservationId, Set<Resource> resources,
			Map<String, List<String>> assetMap, TemplateType templateType) throws IllegalAccessException, InvocationTargetException {
		if (MapUtils.isNotEmpty(assetMap)) {
			Map<Integer, List<Resource>> locationResourceMap = new HashMap<>();
			Map<Integer, String> locationConciergeEmailMap = new HashMap<>();
			for (Resource resource : resources) {
				if (assetMap.containsKey(Integer.toString(resource.getId()))) {
					if (locationResourceMap.containsKey(resource.getLocation().getId())) {
						List<Resource> rsrs = locationResourceMap.get(resource.getLocation().getId());
						rsrs.add(resource);
					} else {
						List<Resource> rsrs = new ArrayList<>();
						rsrs.add(resource);
						locationResourceMap.put(resource.getLocation().getId(), rsrs);
					}
					locationConciergeEmailMap.put(resource.getLocation().getId(),
							resource.getLocation().getConciergeEmail());
				}
			}
			for (Entry<Integer, List<Resource>> e : locationResourceMap.entrySet()) {
				String conciergeEmail = locationConciergeEmailMap.get(e.getKey());
				//conciergeEmail = "naveen.reddy@test.verizon.com";
				ReservationCreationRequestDto reserveCreateDtoCopy = new ReservationCreationRequestDto(reserveCreateDto.getHost(), reserveCreateDto.getCreator(), reserveCreateDto.getResources());
				BeanUtils.copyProperties(reserveCreateDtoCopy, reserveCreateDto);
				reserveCreateDtoCopy.setResources(e.getValue().stream().map(v -> v.getId()).collect(Collectors.toList()));
				emailService.sendConciergeJamboardMail(reserveCreateDtoCopy, reservationId,
						Arrays.asList(conciergeEmail), templateType, null);
			}
		}
	}

    // Cancels reservation and all bookings, use cancel booking to cancel one booking.
    public GoogleStatusResponseReservation cancelReservation(CancelRequestDto cancelRequest, String cancelType) throws IllegalAccessException, InvocationTargetException {
        VzGoogleReservation reservation = vzReservationRepository.getById(cancelRequest.getId());
       
        GoogleStatusResponseReservation response = gsuiteReservationService.cancelReservation(reservation, cancelType);
        vzReservationRepository.saveAndFlush(reservation);
        response.determineStatus();
        
        return response;
    }

	public CallStatusDto cancelReservation(UserDto userDto, String eventId) throws VzException {
		CallStatusDto callStatusDto;
			if (userDto != null && userDto.getEnterpriseId() != null) {
				User user = userRepository.findByEnterpriseId(userDto.getEnterpriseId());
				userDto.setId(user.getId());
				userDto.setCompany(user.getCompany());
				userDto.setGoogleMigrated(user.isGoogleMigrated());
			}
			callStatusDto = cancelReservation(userDto, eventId, BookingStatus.STATUS_TYPE_CANCELLED_USER, true, false);

		return callStatusDto;
	}

    /**
     * Method to cancel the reservation from google
     *
     * @param user
     * @param eventId
     * @return
     */
	public CallStatusDto cancelReservation(UserDto user, String eventId, String cancelType, boolean needResourceGroupInfo, boolean isClientCall) {
		CallStatusDto cancelResponse = new CallStatusDto();
		if (user != null && StringUtils.isNotBlank(eventId) && StringUtils.isNotBlank(cancelType)) {
			String calendarId = (GeneralUtility.isGoogleResource(user.getEmail())
					|| (user.isGoogleMigrated() && !UserService.isOutsideDomainUser(user.getEmail()))) ? user.getEmail()
							: AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL;
			Event event = gsuiteReservationService.getEvent(calendarId, eventId,
					GeneralUtility.isGoogleResource(user.getEmail()));
			if (event == null) {
				Event ltbEvent = gsuiteReservationService.getEvent(AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL, eventId,
						GeneralUtility.isGoogleResource(user.getEmail()));
				if (ltbEvent != null) {
					calendarId = AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL;
					event = ltbEvent;
				}
			}
			if (event != null) {
				cancelResponse = endOrDeleteEvent(calendarId, event);
				if (cancelResponse.getSuccess()) {
					Integer resGroupId = setResourceGroupInfo(event, needResourceGroupInfo);
					if (resGroupId != null)
						cancelResponse.setResourceGroupId(resGroupId);
					notifyUsersOnCancellation(calendarId, user.getEmail(), event, cancelType);
					sendDeleteReqtoClients(event.getId(), event.getRecurrence() != null && event.getRecurrence().size() > 0, isClientCall);
				}
			} else {

				cancelResponse.setSuccessAndMessage(false, "Unable to find the given reservation");
			}
		} else {
			cancelResponse.setSuccessAndMessage(false,
					"Unable to cancel the reservation at the moment. Please try again later.");
		}
		return cancelResponse;
	}

	private void notifyUsersOnCancellation(String calendarId, String hostEmail, Event event, String cancelType) {
		try {
			log.info("Attempting to send Cancellation email to {}" , hostEmail);
			// send email to host
			com.google.api.client.util.DateTime startDateTime = event.getStart().getDate() != null ? event.getStart().getDate() : event.getStart().getDateTime();
			com.google.api.client.util.DateTime endDateTime = event.getEnd().getDate() != null ? event.getEnd().getDate() : event.getEnd().getDateTime();
			DateTime start = new DateTime(startDateTime.getValue()).withZone(DateTimeZone.UTC);
			DateTime end = new DateTime(endDateTime.getValue()).withZone(DateTimeZone.UTC);
			ScheduleHolder scheduleHolder = new ScheduleHolder(start, end, event.getStart().getTimeZone());
			if (!AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL.equals(hostEmail))
				emailService.sendCancellationMail(calendarId, event.getId(), Arrays.asList(hostEmail),
						Boolean.parseBoolean(GsuiteReservationService.getExtendedProperty(event, false, VzConstants.KEY_GSUITE_LONG_TERM_BOOKING))
							? TemplateType.GOOGLE_LTB_CANCELLATION : TemplateType.GOOGLE_BOOKING_CANCELLATION,
						cancelType, scheduleHolder);
			// send email to event support
			Boolean notifyEventSupport = null;
			if (event.getExtendedProperties() != null) {
				String notifyEventSupportValue = GsuiteReservationService.getExtendedProperty(event, false,
						VzConstants.KEY_GSUITE_NOTIFY_EVENT_SUPPORT);
				if (notifyEventSupportValue != null)
					notifyEventSupport = Boolean.parseBoolean(notifyEventSupportValue);
			}
			if (Boolean.TRUE.equals(notifyEventSupport)) {
				SystemPropertyDto eventSupportPropertyDto = systemPropertyService
						.getConfigByName(VzConstants.GSUITE_EVENT_SUPPORT_DL);
				if (eventSupportPropertyDto != null && StringUtils.isNotBlank(eventSupportPropertyDto.getValue()))
					emailService.sendCancellationMailToEventSupport(hostEmail, eventSupportPropertyDto.getValue(),
							calendarId, event.getId(), TemplateType.EVENT_SUPPORT_GOOGLE_BOOKING_CANCELLATION,
							cancelType);
			}
		} catch (ResourceNotFoundException | VzException e) {
			log.error("Exception occured while notifying the users. Details : {}", e.getMessage(), e);
		}
	}

	public void sendDeleteReqtoClients(String eventId, boolean isParentEvent, boolean isClientCall) {
		clientsService.sendDeleteReqToClients(eventId, isParentEvent, isClientCall);
	}
	
	public CallStatusDto endOrDeleteEvent(String userEmail, Event event) {
		CallStatusDto cancelResponse = new CallStatusDto();
		try {
			Boolean pastEvent = GsuiteReservationService.isPastEvent(event);
			if (pastEvent != null && Boolean.FALSE.equals(pastEvent)) {
				Boolean onGoingEvent = GsuiteReservationService.isOngoingEvent(event);
				if (onGoingEvent != null) {
					if (Boolean.TRUE.equals(onGoingEvent)) {
						cancelResponse = gsuiteReservationService.endEvent(event, null)
								? new CallStatusDto(true, "Reservation cancelled successfully")
								: new CallStatusDto(false,
										"Unable to cancel the reservation at this moment. Please try again later");
					} else {
						cancelResponse = gsuiteReservationService.deleteReservation(userEmail, event.getId(),
								GeneralUtility.isGoogleResource(userEmail));
					}
				} else {
					cancelResponse.setSuccessAndMessage(false,
							"Missing few mandatory parameters required to cancel the reservation. Kindly contact the Administrator");
				}
			} else {
				cancelResponse.setSuccessAndMessage(false, "Past events cannot be cancelled!");
			}
		} catch (Exception e) {
			log.error("Exception occured while cancelling the event. Details: {}", e.getMessage(), e);
			cancelResponse.setSuccessAndMessage(false,
					"Unable to cancel the event at the moment. Please try again later.");
		}
		return cancelResponse;
	}
		
//    private List<VzGuiReservationDto> mergeAndSort(List<VzGuiReservationDto> list1, List<VzGuiReservationDto> list2)
//    {
//        List<VzGuiReservationDto> result = new ArrayList<>();
//        result.addAll(list1);
//        result.addAll(list2);
//        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
//        result.sort((o1, o2) ->
//        {
//            long diff = 0;
//            try
//            {
//                diff = (sdf.parse(o1.getSchedule().getStartTime()).getTime()
//                        - sdf.parse(o2.getSchedule().getStartTime()).getTime());
//            }
//            catch (ParseException e)
//            {
//                e.printStackTrace();
//            }
//            return diff > 0 ? 1 : (diff == 0 ? 0 : -1);
//        });
//        return result;
//    }

    public List<Event> userReservations(UserReservationSearchRequest userReservationSearchRequest) {
        try {
            return gsuiteReservationService.listEvents(userReservationSearchRequest, null);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new ArrayList<>();
    }

    public VzGoogleReservation findById(Integer id) throws VzReservationNotFoundException {
        return vzReservationRepository.findById(id).orElseThrow(VzReservationNotFoundException::new);
    }

    private List<VzGoogleReservation> findVzReservations(UserReservationSearchRequest userReservationSearchRequest) {
        org.joda.time.DateTime startDate = new org.joda.time.DateTime().withTimeAtStartOfDay();
        if (userReservationSearchRequest.getIncludeHistoricReservations()) {
            startDate.minusMonths(6);
        }

        if (userReservationSearchRequest.getIncludeCancelledReservations()) {
            return vzReservationRepository.findAllReservations(userReservationSearchRequest.getUser().getEnterpriseId(), startDate.toDate());
        }

        return vzReservationRepository.findReservations(userReservationSearchRequest.getUser().getEnterpriseId(), startDate.toDate());
    }    
	
	public CallStatusDto endOrCancelReservation(String eventId, UserDto userDto) {
		CallStatusDto cancelResponse = new CallStatusDto("Cancellation failed!");
		try {
			if (userDto != null && (StringUtils.isNotBlank(userDto.getEnterpriseId())
					|| StringUtils.isNotBlank(userDto.getEmail()))) {
					cancelResponse = cancelReservation(userDto, eventId, BookingStatus.STATUS_TYPE_CANCELLED_USER_EMAIL, false, false);
			} else {
				cancelResponse.setMessage("User information is not valid!");
			}
		} catch (Exception e) {
			log.error("Exception occured while cancelling the event. Details:{}", e.getMessage(), e);
			cancelResponse.setMessage("Unable to cancel reservations at the moment. Please try again later!.");
		}
		return cancelResponse;
	}

	public ApiResponse<Void> doCheckIn(VzGoogleReservationDto checkInRequest, boolean needResourceGroupInfo) throws VzException {
		ApiResponse<Void> checkInResponse = new ApiResponse<>();
		try {
			VzValidationUtility.isTrue(
					(checkInRequest.getHost() != null
							&& (StringUtils.isNotBlank(checkInRequest.getHost().getEnterpriseId())
							|| StringUtils.isNotBlank(checkInRequest.getHost().getEmail()))),
					VzValidationException.class, "Host details eid or email is required", HttpStatus.BAD_REQUEST);
			VzValidationUtility.isTrue(StringUtils.isNotBlank(checkInRequest.getgSuiteId()),
					VzValidationException.class, "event id is required to check-in", HttpStatus.BAD_REQUEST);
			VzValidationUtility.isTrue(CollectionUtils.isNotEmpty(checkInRequest.getResources()),
					VzValidationException.class,
					"atleast one resource information is required to check in the reservation", HttpStatus.BAD_REQUEST);
			VzValidationUtility.isTrue(
					!checkInRequest.isRecurrentReservation()
							|| GeneralUtility.isRecurringInstance(checkInRequest.getgSuiteId()),
					VzValidationException.class,
					"only child events are considered for check-in incase of reccuring event", HttpStatus.BAD_REQUEST);
			Set<Resource> resources = resourceRepository.findResourcesByIds(
					checkInRequest.getResources().stream().map(ResourceDto::getId).collect(Collectors.toList()));
			VzValidationUtility.isTrue(
					CollectionUtils.isNotEmpty(resources) && resources.size() == checkInRequest.getResources().size(),
					VzValidationException.class, "unable to find one or many resources with the given identifier",
					HttpStatus.BAD_REQUEST);
			String organizerCalendarId;
			String organizerEid;
			boolean isResource = GeneralUtility.isGoogleResource(checkInRequest.getHost().getEmail());
			if (!isResource) {
				log.info("Checking host details: enterpriseId={}, email={} ",
						checkInRequest.getHost().getEnterpriseId(), checkInRequest.getHost().getEmail());
				User host = userService.findByEnterpriseIdOrEmail(checkInRequest.getHost().getEnterpriseId(),
						checkInRequest.getHost().getEmail());
				VzValidationUtility.isTrue(host != null, VzValidationException.class,
						"Unable to find the host with the given information", HttpStatus.BAD_REQUEST);
				organizerCalendarId = host.isGoogleMigrated() && !UserService.isOutsideDomainUser(host.getEmail())
						? host.getEmail()
						: AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL;
				organizerEid = host.getEnterpriseId();
			} else {
				organizerCalendarId = checkInRequest.getHost().getEmail();
				organizerEid = organizerCalendarId;
			}
			Event event = gsuiteReservationService.getEvent(organizerCalendarId, checkInRequest.getgSuiteId(), isResource);
			VzValidationUtility.isTrue(event != null, VzValidationException.class,
					"Unable to find the event in %s calendar".formatted(organizerCalendarId), HttpStatus.BAD_REQUEST);
			VzValidationUtility.isTrue(!GoogleEventStatus.CANCELLED.getName().equals(event.getStatus()),
					VzValidationException.class, "Cancelled events cannot be checked in", HttpStatus.BAD_REQUEST);
			VzValidationUtility.isTrue(GsuiteReservationService.isOngoingEvent(event), VzValidationException.class,
					"Only ongoing events can be checked in", HttpStatus.BAD_REQUEST);
			VzValidationUtility.isTrue(CollectionUtils.isNotEmpty(event.getAttendees()), VzValidationException.class,
					"Unable to find any resources(room) in the given event", HttpStatus.BAD_REQUEST);
			Event updatedEvent = gsuiteReservationService.validateAndCheckIn(event, organizerEid, resources);
			checkInResponse.withSuccess(updatedEvent != null)
					.withMessage(updatedEvent != null ? "Checked in successfully"
							: "Unable to checkin reservations at the moment. Please try again later!.");
            Integer resGroupId = setResourceGroupInfo(event, needResourceGroupInfo);
            if (resGroupId != null) {
                checkInResponse.setResourceGroupId(resGroupId);
            }
            Set<Integer> resourceIds = checkInRequest.getResources().stream().map(r -> r.getId()).collect(Collectors.toSet());
//			Set<Integer> smartHubRooms = smhubService.getSmartHubRooms(resourceIds);
//			if (VzConstants.YES.equals(systemPropertyService.getPropertyValueFromDb(VzConstants.SYS_PROP_LOAD_SMARTHUB_RESOURCE_CHECKIN_INFO_TO_CACHE)) && CollectionUtils.isNotEmpty(smartHubRooms)) {
//				if (VzConstants.YES.equals(systemPropertyService.getPropertyValueFromDb(VzConstants.SYS_PROP_ENABLE_GSUITE_UPDATE_EVENT_LOGS))) {
//					log.info("Room/s {} Event Information before cache upload {}", resourceIds, event.toPrettyString());
//					log.info("Resource/s {} is a smarthub room. Proceeding to load check-in info to cache", resourceIds);
//				}
//				List<String> resourceCalendarIds = resources.stream().filter(r -> smartHubRooms.contains(r.getId())).map(Resource::getEmail).collect(Collectors.toList());
				clientsService.loadSmarthubResourceCheckinInfoToCache(resourceIds, checkInRequest.getgSuiteId());
				smarthubDataProviderService.updateCheckinInSmarthubCache(resourceIds, checkInRequest.getgSuiteId());
//			}


		} catch (VzException e) {
			throw e;
		} catch (Exception e) {
			log.error("Exception occured while checking-in the event. Details:{}", e.getMessage(), e);
			checkInResponse.setMessage("Unable to checkin reservations at the moment. Please try again later!.");
		}
		return checkInResponse;
	}

	public Integer setResourceGroupInfo(Event event, boolean needResourceGroupInfo) {
		if (needResourceGroupInfo) {
			String resourceEmail = event.getAttendees().stream()
					.filter(Objects::nonNull)
					.filter(EventAttendee::isResource)
					.map(EventAttendee::getEmail)
					.filter(Objects::nonNull)
					.findFirst().orElse(null);
			if (StringUtils.isNotBlank(resourceEmail)) {
				Resource resource = resourceRepository.findByEmail(resourceEmail).get(0);
				if (resource != null && resource.getResourceGroup() != null)
					return resource.getResourceGroup().getId();
			}
		}
		return null;
	}

	public VzReservationDto getUserEventById(UserDto user, String eventId) throws VzException {
		if (user != null && StringUtils.isNotBlank(eventId)) {
			String calendarId = (GeneralUtility.isGoogleResource(user.getEmail())
					|| (user.isGoogleMigrated() && !UserService.isOutsideDomainUser(user.getEmail()))) ? user.getEmail()
					: AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL;
			Event event = gsuiteReservationService.getEvent(calendarId, eventId,
					GeneralUtility.isGoogleResource(user.getEmail()));
			if(event != null) {
				List<Integer> favResourcesMap = userService.getFavRooms(user.getEnterpriseId());
				List<Event> events = new ArrayList<>();
				events.add(event);
				List<VzReservationDto> reservationDtos = userService.processGsuiteEvents(events, user, favResourcesMap);
				return reservationDtos.get(0);
			}else {
				throw new VzException("Unable to find the given google event", HttpStatus.NOT_FOUND);
			}
		}
		return null;
	}

	public void updateCheckinDataInGoogleCache(Set<Integer> resourceIds, String gsuiteId){
		List<Object[]> resourceDetails = resourceRepository.findDetailsOfAllResources(resourceIds, false);
		Set<String> smarthubEmails = smarthubDataProviderService.getAllSmarthubResEmails();
		if (CollectionUtils.isNotEmpty(resourceDetails) && CollectionUtils.isNotEmpty(smarthubEmails)) {
			resourceDetails.stream().filter(Objects::nonNull).filter(resource -> resource.length >= 10).forEach(r -> {
				Integer resourceId = (Integer) r[0];
				Integer floorId = (Integer) r[1];
				Integer locationId = (Integer) r[2];
				String resourceEmail = (String) r[3];
				if (smarthubEmails.contains(resourceEmail)) {
					log.info("Attempting to update check-in data in the cache for the resourceId - {}, G-suiteId - {}", resourceId, gsuiteId);
					dataStorageService.updateGoogleResourceCheckin(locationId, floorId, resourceId, gsuiteId, resourceEmail);
				}
			});
		}
	}

}


package com.verizon.vzreserve.gsuite.service;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.Map.Entry;
import java.util.function.Function;
import java.util.stream.Collectors;

import com.verizon.vzreserve.service.GoogleReservationService;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.collections4.MapUtils;
import org.apache.commons.lang3.StringUtils;
import org.dmfs.rfc5545.recur.InvalidRecurrenceRuleException;
import org.dmfs.rfc5545.recur.RecurrenceRule;
import org.joda.time.DateTimeZone;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.Assert;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.api.client.googleapis.json.GoogleJsonResponseException;
import com.google.api.client.util.DateTime;
import com.google.api.services.calendar.Calendar;
import com.google.api.services.calendar.model.Event;
import com.google.api.services.calendar.model.Event.Creator;
import com.google.api.services.calendar.model.Event.ExtendedProperties;
import com.google.api.services.calendar.model.EventAttendee;
import com.google.api.services.calendar.model.EventDateTime;
import com.google.api.services.calendar.model.Events;
import com.google.common.collect.ImmutableSet;
import com.verizon.vzreserve.config.systemproperty.SystemPropertyService;
import com.verizon.vzreserve.dao.entity.BookingStatus;
import com.verizon.vzreserve.dao.entity.Resource;
import com.verizon.vzreserve.dao.entity.Schedule;
import com.verizon.vzreserve.dao.entity.VzGoogleBooking;
import com.verizon.vzreserve.dao.entity.VzGoogleReservation;
import com.verizon.vzreserve.dao.entity.VzReservation;
import com.verizon.vzreserve.dao.repository.ResourceRepository;
import com.verizon.vzreserve.dto.CallStatusDto;
import com.verizon.vzreserve.dto.ExtendedPropertyWrapper;
import com.verizon.vzreserve.dto.GoogleBookingAddRequestDto;
import com.verizon.vzreserve.dto.GoogleStatusResponseReservationDto;
import com.verizon.vzreserve.dto.ReservationCreationRequestDto;
import com.verizon.vzreserve.dto.ResourceDto;
import com.verizon.vzreserve.dto.ScheduleDto;
import com.verizon.vzreserve.dto.UserDto;
import com.verizon.vzreserve.dto.UserReservationSearchRequest;
import com.verizon.vzreserve.dto.VzGoogleBookingDto;
import com.verizon.vzreserve.dto.VzGoogleReservationDto;
import com.verizon.vzreserve.dto.model.GoogleStatusResponseReservation;
import com.verizon.vzreserve.dto.model.ScheduleHolder;
import com.verizon.vzreserve.dto.model.StatusResponse;
import com.verizon.vzreserve.enums.MeetingResponseStatus;
import com.verizon.vzreserve.exception.VzException;
import com.verizon.vzreserve.exception.VzValidationException;
import com.verizon.vzreserve.gsuite.exception.VzGoogleException;
import com.verizon.vzreserve.gsuite.utils.AuthenticationCredentialCalendar;
import com.verizon.vzreserve.gsuite.utils.CommonUtility;
import com.verizon.vzreserve.service.ScheduleProviderService;
import com.verizon.vzreserve.service.UserService;
import com.verizon.vzreserve.utils.DateTimeUtility;
import com.verizon.vzreserve.utils.GeneralUtility;
import com.verizon.vzreserve.utils.VzConstants;
import com.verizon.vzreserve.utils.VzValidationUtility;


@Service
public class GsuiteReservationService {
	
	private static final Logger logger = LoggerFactory.getLogger(GsuiteReservationService.class);
	
    @Autowired
    private CalendarAuthenticationService calendarAuthenticationService;

    @Autowired
    private ResourceRepository roomRepository;

    private Calendar calendar;

    @Value("${environment}")
    private String environment;

    @Autowired
    private ScheduleProviderService scheduleProviderService;

    private final Logger log = LoggerFactory.getLogger(this.getClass());
    
    @Autowired
    private ObjectMapper objectMapper;
    
	@Autowired
	private SystemPropertyService systemPropertyService;

    @Lazy
    @Autowired
    private GoogleReservationService googleReservationService;


    /**
     * Method to insert event using Insert API in Google Calendar API
     *
     * @param event: Event object from createEvent API
     * @return Event
     */
    private Event insertEvent(Event event) {
        try {
            String calendarId = event.getCreator().getEmail();
            String host = event.getOrganizer().getEmail() != null ? event.getOrganizer().getEmail() : calendarId;
            Calendar calendar = calendarAuthenticationService.calendarAuthentication(calendarId);
            if (calendar == null) {
                return null;
            }
            return calendar.events()
                    .insert(host, event)
                    .setSendUpdates("all")
                    .execute();
        } catch (GoogleJsonResponseException ex) {
            System.out.println(ex.getDetails());
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    private Event createEvent(ReservationCreationRequestDto reservationDto, Collection<Resource> gSuiteResources, boolean autoCheckIn, String eventFrom) {
        // Adding creator of the event
        Event.Creator creator = new Event.Creator();
        if (reservationDto.getCreator().isGoogleMigrated() && !UserService.isOutsideDomainUser(reservationDto.getCreator().getEmail())
                && !Boolean.TRUE.equals(reservationDto.getLongTermBooking())) {
            creator.setEmail(reservationDto.getCreator().getEmail());
        } else {
            creator.setEmail(AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL);
        }

        // Adding organizer of the event
        Event.Organizer organizer = new Event.Organizer();
        if (reservationDto.getHost().isGoogleMigrated() && !UserService.isOutsideDomainUser(reservationDto.getHost().getEmail())
                && !Boolean.TRUE.equals(reservationDto.getLongTermBooking())) {
        	organizer.setEmail(reservationDto.getHost().getEmail());
        } else {
        	organizer.setEmail(AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL);
        }


        List<EventAttendee> attendeesList = new ArrayList<>();
        if(reservationDto.getHost().isGoogleMigrated() && !UserService.isOutsideDomainUser(reservationDto.getHost().getEmail())
                && !Boolean.TRUE.equals(reservationDto.getLongTermBooking())) {
            // Organizer also must be added as an event attendee
            EventAttendee eventOrganizer = new EventAttendee();
            eventOrganizer.setEmail(reservationDto.getHost().getEmail());
            eventOrganizer.setOrganizer(true);
            eventOrganizer.setResponseStatus(MeetingResponseStatus.ACCEPTED.getName());
            attendeesList.add(eventOrganizer);
        }


        if (reservationDto.getAttendees() != null) {
            List<EventAttendee> attendees = reservationDto.getAttendees().stream()
                    .map(user -> new EventAttendee().setEmail(user.getEmail()))
                    .collect(Collectors.toList());
            // Adding people to the list of attendees
            attendeesList.addAll(attendees);
        }

        // Adding rooms to the list of attendees
        // Covers both single room and multi room reservations
        gSuiteResources.stream()
                .map(resource -> new EventAttendee().setEmail(resource.getEmail()).setResource(true))
                .forEach(attendeesList::add);
        
        Event event = new Event();

        if (reservationDto.isRecurrentReservation()) {
            List<String> recurrence = new ArrayList<>();
            recurrence.add(reservationDto.getRecurrenceRule());
            event.setRecurrence(recurrence);
        }

        event.setSummary(reservationDto.getTitle());
        event.setAttendees(attendeesList);
        event.setOrganizer(organizer);
        event.setCreator(creator);

        //Setting extended properties        
		//set time-zone in which the event is supposed to exist
        createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_TIMEZONE,
                reservationDto.getSchedule().getTimeZone());
        if (StringUtils.isNotBlank(eventFrom)){
            createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_SOURCE, eventFrom);
            createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_IS_ADMIN,
                    (eventFrom.equals(VzConstants.BAS_ADMIN_EVENT) || eventFrom.equals(VzConstants.BAS_ADMIN_MAINTENANCE)) ? String.valueOf(Boolean.TRUE) : String.valueOf(Boolean.FALSE));
        }

		//set creator-eid for outlook or vzc users
		if (!reservationDto.getCreator().isGoogleMigrated()
				|| UserService.isOutsideDomainUser(reservationDto.getCreator().getEmail())
                || Boolean.TRUE.equals(reservationDto.getLongTermBooking()))
			createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_USER_EID,
					reservationDto.getCreator().getEnterpriseId());

		//set check-in enabled resource details
        String checkinEnabledResources = getCheckinEnabledResources(gSuiteResources);
		if (!StringUtils.isEmpty(checkinEnabledResources)) {
			createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_CHECKIN, Boolean.TRUE.toString());
			createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_CHECKIN_RES_ID,
					checkinEnabledResources);
		}

		//set jamboards requested for this event
		if (MapUtils.isNotEmpty(reservationDto.getAssetMap())) {
			try {
				createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_ASSETS,
						objectMapper.writeValueAsString(reservationDto.getAssetMap()));
			} catch (JsonProcessingException e) {
				log.error("Unable to map assest to the given resource. Details: {}", e.getMessage(), e);
			}
		}

		//set event support request flag
		createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_NOTIFY_EVENT_SUPPORT,
				String.valueOf(Boolean.TRUE.equals(reservationDto.getNotifyEventSupport())));

        createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_LONG_TERM_BOOKING,
                String.valueOf(Boolean.TRUE.equals(reservationDto.getLongTermBooking())));
        if(!StringUtils.isEmpty(reservationDto.getReason())){
            createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_LTB_REASON,
                    reservationDto.getReason());
        }
		//check and check-in the event
		if (autoCheckIn) {
			try {
				validateAndPutCheckInProperties(event, reservationDto.getHost().getEnterpriseId(), gSuiteResources);
			} catch (VzValidationException e) {
				logger.error("Exception occured while checking-in the event. Details: {}", e.getMessage(), e);
			}
		}
        List<Resource> resources = new ArrayList<>(gSuiteResources);
        //TODO: Change/check the schedule holder workflow
        ScheduleHolder scheduleHolder = getScheduleHolder(reservationDto, resources.get(0));
        String timeZone = reservationDto.getSchedule().getTimeZone();


        // Start and end times are in UTC
        event.setStart(new EventDateTime().setDateTime(DateTime.parseRfc3339(scheduleHolder.getStartTime().toString())).setTimeZone(timeZone));
        event.setEnd(new EventDateTime().setDateTime(DateTime.parseRfc3339(scheduleHolder.getEndTime().toString())).setTimeZone(timeZone));
        return event;
    }

    private String getCheckinEnabledResources(Collection<Resource> gsuiteResources) {
        List<Resource> resourcesWithCheckinEnabled = gsuiteResources.stream()
                .filter(resource -> resource.getCheckInEnabled() != null)
                .filter(Resource::getCheckInEnabled)
                .collect(Collectors.toList());

        if (resourcesWithCheckinEnabled.size() > 0) {
            return resourcesWithCheckinEnabled.stream()
                    .map(Resource::getId)
                    .map(String::valueOf)
                    .collect(Collectors.joining(","));
        } else {
            return null;
        }
    }

    private Event waitAndCheckResponseStatusOfResource(Event insertedEvent) {
        int count = 0;
        List<EventAttendee> resourceList;
        Event afterInsertion = insertedEvent; //just initializing
        while (count < VzConstants.GSUITE_AFTER_RESERVATION_WAIT_TIME) {
            try {
                boolean shouldContinue = false;
                if (count == 0) {
                    Thread.sleep(3000);
                } else {
                    Thread.sleep(1000);
                }

                afterInsertion = getEvent(insertedEvent.getOrganizer().getEmail(), insertedEvent.getId(),
                        GeneralUtility.isGoogleResource(insertedEvent.getOrganizer().getEmail()));

                resourceList = getResourcesFromEvent(afterInsertion);
                System.out.println(afterInsertion.toPrettyString());

                for (EventAttendee resource : resourceList) {
                    if (resource.getResponseStatus().equals(MeetingResponseStatus.NEEDS_ACTION.getName())) {
                        shouldContinue = true;
                        break;
                    }
                }
                if (!shouldContinue) {
                    break;
                }
                count++;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return afterInsertion;
    }

    public Event updateEvent(Event event, boolean notifyUser, String client) {
        try {
            if(VzConstants.YES.equals(systemPropertyService.getPropertyValueFromDb(VzConstants.SYS_PROP_ENABLE_GSUITE_UPDATE_EVENT_LOGS))) {
                logger.info("eventId - {} notifyUser - {} client - {}", event.getId(), notifyUser, client);
                if (CollectionUtils.isNotEmpty(event.getAttendees())) {
                    for (EventAttendee attendee : event.getAttendees()) {
                        logger.info("eventId - {} - attendee  - {}", event.getId(), attendee.getEmail());
                    }
                }
            }
            String eventId = event.getId();
            String hostId = event.getOrganizer().getEmail();
            calendar = calendarAuthenticationService.calendarAuthentication(hostId);
            return calendar.events()
                    .update(hostId, eventId, event)
                    .setSendUpdates(notifyUser ? "all" : "none")
                    .execute();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    //Recurrent case: uses instances api instead of get
    private List<Event> waitAndCheckResponseStatusOfResourceWithRecurrence(Event insertedEvent) {
		List<Event> allEvents = getInstancesOfRecurringEvent(insertedEvent.getOrganizer().getEmail(),
				insertedEvent.getOrganizer().getEmail(), insertedEvent.getId());

        int resourcesCount = getResourcesFromEvent(allEvents.get(0)).size();

        List<String> validatedEvents = new ArrayList<>();

        int count = 0;
        // Google api response for response status is ambiguous. Hence, checking if it not null and true for resource attendees
        List<EventAttendee> resourceList;
        while (count < VzConstants.GSUITE_AFTER_RESERVATION_WAIT_TIME) {
            try {
                if (count == 0) {
                    Thread.sleep(3000);
                } else {
                    Thread.sleep(1000);
                }
                allEvents = getInstancesOfRecurringEvent(insertedEvent.getOrganizer().getEmail(), insertedEvent.getOrganizer().getEmail(),
                        insertedEvent.getId());
                allEvents.stream()
                        .filter(event -> !validatedEvents.contains(event.getId()))
                        .forEach(event -> {
                            List<EventAttendee> resources = getResourcesFromEvent(event);
                            long resourcesWithStatus = resources.stream()
                                    .filter(resource -> !resource.getResponseStatus().equalsIgnoreCase(MeetingResponseStatus.NEEDS_ACTION.getName()))
                                    .count();
                            if (resourcesWithStatus == resourcesCount) {
                                validatedEvents.add(event.getId());
                            }
                        });
                if (validatedEvents.size() == allEvents.size()) {
                    break;
                }
                count++;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return allEvents;
    }

    private static boolean allTrue(boolean[] values) {
        for (boolean value : values) {
            if (!value) {
                return false;
            }
        }
        return true;
    }

	private List<EventAttendee> getResourcesFromEvent(Event event) {
		return event != null ? event.getAttendees().stream().filter(e -> e.getResource() != null && e.getResource())
				.collect(Collectors.toList()) : Collections.emptyList();
	}

    private void checkStatusAndFormResponse(Event event, GoogleStatusResponseReservation response, Collection<Resource> gSuiteResources) {
        VzGoogleBooking successVzBooking = new VzGoogleBooking();
        VzGoogleBooking failedVzBooking = new VzGoogleBooking();
        successVzBooking.setSchedule(new Schedule(event.getStart(), event.getEnd(), null));
        failedVzBooking.setSchedule(new Schedule(event.getStart(), event.getEnd(), null));

        List<EventAttendee> resourceList = getResourcesFromEvent(event);
        Map<String, Resource> gSuiteResourceMap = gSuiteResources.stream()
                .collect(Collectors.toMap(Resource::getEmail, Function.identity(), (key1, Key2) -> key1));

        resourceList.stream()
                .filter(resource -> gSuiteResourceMap.containsKey(resource.getEmail()))
                .forEach(resource -> {
                    if (resource.getResponseStatus().equals(MeetingResponseStatus.ACCEPTED.getName())) {
                        response.setSorId(event.getId());
                        Resource room = gSuiteResourceMap.get(resource.getEmail());
                        if (room != null) {
                            successVzBooking.setGSuiteId(event.getId());
                            successVzBooking.addResource(room);
                        }
                    } else {
                        Resource room = gSuiteResourceMap.get(resource.getEmail());
                        if (room != null) {
                            failedVzBooking.addResource(room);
                        }
                    }
                });

        if (!failedVzBooking.getResources().isEmpty()) {
            response.addFailedBooking(failedVzBooking);
        }
        if (!successVzBooking.getResources().isEmpty()) {
            Resource resource = successVzBooking.getResources().iterator().next();
            if(resource != null ) {
                String rgIdStr = systemPropertyService.getPropertyValue(VzConstants.SYS_PROP_RES_INFO_RESOURCE_GROUPS);
                Set<Integer> rgIds = StringUtils.isNotEmpty(rgIdStr) ? Arrays.stream(rgIdStr.split(VzConstants.DELIMITER_COMMA)).map(Integer::parseInt)
                        .collect(Collectors.toSet()) : new HashSet<>();

                String rtIdStr = systemPropertyService.getPropertyValue(VzConstants.SYS_PROP_RES_INFO_RESOURCE_TYPES);
                Set<Integer> rtIds = StringUtils.isNotEmpty(rtIdStr) ? Arrays.stream(rtIdStr.split(VzConstants.DELIMITER_COMMA)).map(Integer::parseInt)
                        .collect(Collectors.toSet()) : new HashSet<>();
                if(rgIds.contains(resource.getResourceGroup().getId()) || rtIds.contains(resource.getResourceType().getId())) {
                    successVzBooking.addInfo(VzConstants.GSUITE_AUTO_CANCELATION_MSG);
                }

            }
            response.addSuccessBooking(successVzBooking);
        }

    }

    public GoogleStatusResponseReservation modifyBooking(VzGoogleReservation reservation,
                                                         VzGoogleBooking booking) throws VzGoogleException {
        GoogleStatusResponseReservation response = new GoogleStatusResponseReservation();

        String calendarId = CommonUtility.convertEmail(reservation.getHost().getEmail(), environment);
        String eventId = booking.getGSuiteId();

        try {
            Event event = getEvent(calendarId, eventId, GeneralUtility.isGoogleResource(calendarId));

            if (event == null) {
                response.setStatus(StatusResponse.ERROR);
                response.addFailedBooking(booking);
                return response;
            }

            // New list of attendees(users and resources)
            List<EventAttendee> eventAttendees = new ArrayList<>();

            // segregating users from resources in old list adding to new list
            for (EventAttendee eventAttendee : event.getAttendees()) {
                if (!eventAttendee.getResource()) {
                    eventAttendees.add(eventAttendee);
                }
            }

            // add resources from request into attendee list
            for (Resource resource : booking.getResources()) {
                eventAttendees.add(new EventAttendee().setEmail(resource.getEmail()).setResource(true));
            }

            event.setAttendees(eventAttendees);

            String timeZone = event.getStart().getTimeZone();

            // Conversion
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
            sdf.setTimeZone(TimeZone.getTimeZone("UTC"));

            String start = sdf.format(booking.getSchedule().getStartTime());
            String end = sdf.format(booking.getSchedule().getEndTime());

            event.setStart(new EventDateTime().setDateTime(DateTime.parseRfc3339(start)).setTimeZone(timeZone));
            event.setEnd(new EventDateTime().setDateTime(DateTime.parseRfc3339(end)).setTimeZone(timeZone));

            Event updatedEvent = updateEvent(event, true, "modifyBooking");

            if (updatedEvent == null) {
                response.setStatus(StatusResponse.ERROR);
                response.addFailedBooking(booking);
                return response;
            }
            updatedEvent = waitAndCheckResponseStatusOfResource(updatedEvent);
            List<EventAttendee> resourceList = getResourcesFromEvent(updatedEvent);

            VzGoogleBooking failedBooking = new VzGoogleBooking();

            for (EventAttendee resource : resourceList) {
                Resource res = null;
                for (Resource findResource : booking.getResources()) {
                    if (findResource.getEmail().equals(resource.getEmail())) {
                        res = findResource;
                        break;
                    }
                }

                // One of the added rooms
                if (res != null) {
                    if (resource.getResponseStatus().equals(MeetingResponseStatus.ACCEPTED.getName())) {
                        booking.addResource(res);
                    } else {
                        failedBooking.addResource(res);
                    }
                }
            }

            if (booking.getResources().isEmpty()) {
                booking.setBookingStatus(new BookingStatus(BookingStatus.STATUS_CANCELLED, BookingStatus.STATUS_TYPE_RESCHEDULE_CANCEL));
            }

            if (!failedBooking.getResources().isEmpty()) {
                response.addFailedBooking(failedBooking);
            }
        } catch (Exception e) {
            e.printStackTrace();
            throw new VzGoogleException(e.getMessage(), e);
        }

        return response;
    }


    public GoogleStatusResponseReservation addRoomsToBooking(VzGoogleReservation reservation, VzGoogleBooking booking, Collection<Resource> addResources) throws VzGoogleException {
        GoogleStatusResponseReservation response = new GoogleStatusResponseReservation();

        String calendarId = CommonUtility.convertEmail(reservation.getHost().getEmail(), environment);

        try {
            Event event = getEvent(calendarId, reservation.getGSuiteId(), GeneralUtility.isGoogleResource(calendarId));

            if (event == null) {
                throw new VzGoogleException("Event is null");
            }

            for (Resource resource : addResources) {
                event.getAttendees().add(new EventAttendee().setEmail(resource.getEmail()).setResource(true));
            }

            Event updatedEvent = updateEvent(event, true, "addRoomsToBooking");
            if (updatedEvent == null) {
                response.setStatus(StatusResponse.ERROR);
                return response;
            }
            waitAndCheckResponseStatusOfResource(updatedEvent);
            List<EventAttendee> resourceList = getResourcesFromEvent(updatedEvent);

            VzGoogleBooking failedBooking = new VzGoogleBooking();

            for (EventAttendee resource : resourceList) {
                Resource res = null;
                for (Resource findResource : addResources) {
                    if (findResource.getEmail().equals(resource.getEmail())) {
                        res = findResource;
                        break;
                    }
                }

                // One of the added rooms
                if (res != null) {
                    if (resource.getResponseStatus().equals(MeetingResponseStatus.ACCEPTED.getName())) {
                        booking.addResource(res);
                    } else {
                        failedBooking.addResource(res);
                    }
                }
            }

            if (!failedBooking.getResources().isEmpty()) {
                response.addFailedBooking(failedBooking);
            }

            return response;
        } catch (Exception e) {
            e.printStackTrace();
            throw new VzGoogleException(e.getMessage(), e);
        }
    }

    /**
     * Method to make a reservation
     *
     * @return Reservation
     */
    public GoogleStatusResponseReservation makeReservation(GoogleBookingAddRequestDto addRequest, VzReservation reservation, Collection<Resource> resources, String eventFrom) {
        ReservationCreationRequestDto reservationCreationRequestDto = new ReservationCreationRequestDto(addRequest.getUser(), addRequest.getUser(), Arrays.asList(-1));

        reservationCreationRequestDto.setSchedule(addRequest.getBooking().getSchedule());
        reservationCreationRequestDto.setHost(addRequest.getUser());
        reservationCreationRequestDto.setAttendees(addRequest.getBooking().getAttendees());
        reservationCreationRequestDto.setTitle(reservation.getTitle());
        GoogleStatusResponseReservation creationStatusResponse = makeReservation(reservationCreationRequestDto, resources, false, eventFrom);
        googleReservationService.updateReservationInBookingAudit(creationStatusResponse, eventFrom, null, null,Boolean.TRUE.equals(reservationCreationRequestDto.getNotifyEventSupport()));
        return creationStatusResponse;
    }

    public GoogleStatusResponseReservation makeReservation(ReservationCreationRequestDto reservationDto, Collection<Resource> gSuiteResources, boolean autoCheckIn, String eventFrom) {

        CommonUtility.transformEmails(reservationDto, environment);

        Event event = createEvent(reservationDto, gSuiteResources, autoCheckIn, eventFrom);
        GoogleStatusResponseReservation response = new GoogleStatusResponseReservation();

        try {
            Event insertedEvent;
            if(StringUtils.isEmpty(reservationDto.getgSuiteId())) {
                 insertedEvent = insertEvent(event);

            } else {
                event.setId(reservationDto.getgSuiteId());
                insertedEvent = updateEvent(event, true, "makeReservation");
            }

            if (insertedEvent == null) {
                throw new VzGoogleException("Authentication failure in Google");
            }

            List<Event> allEvents;

            if (reservationDto.isRecurrentReservation()) {
                allEvents = waitAndCheckResponseStatusOfResourceWithRecurrence(insertedEvent);
                for (Event _event : allEvents) {
//                    _event = getEvent(_event.getOrganizer().getEmail(), _event.getId(), GeneralUtility.isGoogleResource(_event.getOrganizer().getEmail()));
                    checkStatusAndFormResponse(_event, response, gSuiteResources);
                }
            } else {
                waitAndCheckResponseStatusOfResource(insertedEvent);
                insertedEvent = getEvent(insertedEvent.getOrganizer().getEmail(), insertedEvent.getId(), GeneralUtility.isGoogleResource(insertedEvent.getOrganizer().getEmail()));
                checkStatusAndFormResponse(insertedEvent, response, gSuiteResources);
            }
            response.setSorId(insertedEvent.getId());
        } catch (VzGoogleException vzg) {
            vzg.printStackTrace();
            for (Resource resource : gSuiteResources) {
                response.addFailedBooking(new VzGoogleBooking(resource,
                        new Schedule(scheduleProviderService.prepareSchedule(reservationDto.getSchedule()))));
            }
            response.setStatus(GoogleStatusResponseReservationDto.ERROR);
        } catch (Exception e) {
            e.printStackTrace();
        }

        return response;
    }

    /**
     * Method to get an Event
     *
     * @param calendarId: Unique identifier of a Room
     * @param eventId:    Unique identifier of a reservation
     * @param useSvc: Boolean to determine the usage of service account for authentication
     * @return Event
     */

    public Event getEvent(String calendarId, String eventId, boolean useSvc) {
        try {
            calendar = useSvc ? calendarAuthenticationService.calendarAuthentication()
                    : calendarAuthenticationService.calendarAuthentication(calendarId);
            if (calendar == null) {
                return null;
            }

            return calendar.events().get(calendarId, eventId).setTimeZone("UTC").execute();
        } catch (GoogleJsonResponseException ex) {
            if (ex.getStatusCode() == 404) {
                System.out.println(ex.getDetails());
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Method to delete an event using Google Calendar API
     *
     * @param emailId  : Email of the host
     * @param eventId: Unique id obtained after making a successful reservation
     * @param useSvc: Boolean to determine the usage of service account for authentication
     * @return true if successfully deleted. Else, false.
     */

    private boolean deleteEvent(String emailId, String eventId, boolean useSvc) {
        try {
            calendar = useSvc ? calendarAuthenticationService.calendarAuthentication()
                    : calendarAuthenticationService.calendarAuthentication(emailId);
            calendar.events().delete(emailId, eventId).setSendUpdates("all").execute();
            return true;
        } catch (GoogleJsonResponseException ex) {
            System.out.println(ex.getDetails());
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }

    /**
     * Method to cancel a reservation / google master event
     */
    public GoogleStatusResponseReservation cancelReservation(VzGoogleReservation reservation, String cancelType) {
        GoogleStatusResponseReservation response = new GoogleStatusResponseReservation();
        response.setReservationId(reservation.getId());
        response.setSorId(reservation.getGSuiteId());

        String hostEmail = CommonUtility.convertEmail(reservation.getHost().getEmail(), environment);

        for (VzGoogleBooking booking : reservation.getBookings()) {
            if (deleteEvent(hostEmail, booking.getGSuiteId(), GeneralUtility.isGoogleResource(hostEmail)))  // Define
            {
                booking.setBookingStatus(new BookingStatus(BookingStatus.STATUS_CANCELLED, cancelType));
                response.addSuccessBooking(booking);
            } else {
                response.addFailedBooking(booking);
            }
        }

        return response;
    }

    public CallStatusDto deleteReservation(String email, String eventId, boolean useSvc) {
        CallStatusDto response = new CallStatusDto();
        boolean isCanceledSuccessfully = deleteEvent(email, eventId, useSvc);
        response.setSuccess(isCanceledSuccessfully);
        if (isCanceledSuccessfully) {
            response.setMessage("Reservation cancelled successfully.");
        } else {
            response.setMessage("Unable to cancel the reservation at this moment. Please try again later");
        }
        return response;
    }

	public VzGoogleReservationDto getReservation(Event event) {
		VzGoogleReservationDto reservation = null;
		if (event != null) {
			reservation = new VzGoogleReservationDto();
			reservation.setgSuiteId(event.getId());
			reservation.setTitle(event.getSummary());
			reservation.setCreateTime(event.getCreated() != null ? new Date(event.getCreated().getValue()) : null);
			reservation.setUpdateTime(event.getUpdated() != null ? new Date(event.getUpdated().getValue()) : null);
			reservation.setCreator(event.getCreator() != null
					? new UserDto(event.getCreator().getDisplayName(), event.getCreator().getEmail())
					: null);
			reservation.setHost(event.getOrganizer() != null
					? new UserDto(event.getOrganizer().getDisplayName(), event.getOrganizer().getEmail())
					: null);
			reservation.setRecurrenceRule(
					!CollectionUtils.isEmpty(event.getRecurrence()) ? event.getRecurrence().get(0) : "");
			reservation.setRecurringEventId(event.getRecurringEventId());
			reservation.setBookings(ImmutableSet.of(getBooking(event)));
		}
		return reservation;
	}

	private VzGoogleBookingDto getBooking(Event event) {
		VzGoogleBookingDto booking = null;
		if (event != null) {
			booking = new VzGoogleBookingDto();
			booking.setGSuiteId(event.getId());
			booking.setParentGsuiteId(event.getRecurringEventId());
			if (!CollectionUtils.isEmpty(event.getAttendees())) {
				Set<UserDto> attendees = new HashSet<>();
				Set<String> resourceEmails = new HashSet<>();
				event.getAttendees().stream().filter(Objects::nonNull).filter(e -> StringUtils.isNotBlank(e.getEmail()))
						.forEach(ea -> {
							if (ea.isResource()) {
								resourceEmails.add(ea.getEmail());
							} else if (event.getOrganizer() != null
									&& StringUtils.isNoneBlank(event.getOrganizer().getEmail())
									&& !event.getOrganizer().getEmail().equalsIgnoreCase(ea.getEmail())) {
								attendees.add(new UserDto(
										StringUtils.isNotBlank(ea.getDisplayName()) ? ea.getDisplayName()
												: GeneralUtility.buildNameFromMailAddress(ea.getEmail()),
										ea.getEmail()));
							}
						});
				Set<Resource> resources = roomRepository.findByFullNameIn(resourceEmails);
				if (CollectionUtils.isNotEmpty(resources))
					booking.setResources(ResourceDto.parseSet(resources));
				booking.setAttendees(attendees);
			}
			String timeZone = (event.getExtendedProperties() != null
					&& GsuiteReservationService.getExtendedProperty(event, false, VzConstants.KEY_GSUITE_TIMEZONE) != null)
							? GsuiteReservationService.getExtendedProperty(event, false, VzConstants.KEY_GSUITE_TIMEZONE)
							: "";
			booking.setSchedule(getSchedule(event, timeZone, booking.getResources()));
		}
		return booking;
	}

	private ScheduleDto getSchedule(Event event, String timeZone, List<ResourceDto> resources) {
		if (StringUtils.isBlank(timeZone)) {
			if (event.getStart() != null && StringUtils.isNotBlank(event.getStart().getTimeZone())) {
				timeZone = event.getStart().getTimeZone();
			} else if (event.getEnd() != null && StringUtils.isNotBlank(event.getEnd().getTimeZone())) {
				timeZone = event.getEnd().getTimeZone();
			} else if (!CollectionUtils.isEmpty(resources)) {
				timeZone = resources.get(0).getLocationTimeZone();
				if (StringUtils.isBlank(timeZone))
					timeZone = DateTimeUtility.UTC_ZONE_ID;
			} else {
				timeZone = DateTimeUtility.UTC_ZONE_ID;
			}
		}
		return scheduleProviderService.getScheduleDto(
				scheduleProviderService.prepareSchedule(new Schedule(event.getStart(), event.getEnd(), timeZone)));
	}

    /**
     * Method to cancel a single booking / event
     */
    public GoogleStatusResponseReservation cancelBooking(VzGoogleBooking booking, String cancelType) {
        GoogleStatusResponseReservation response = new GoogleStatusResponseReservation();
        response.setReservationId(booking.getReservation().getId());
        response.setSorId(booking.getGSuiteId());

        String hostEmail = CommonUtility.convertEmail(booking.getReservation().getHost().getEmail(), environment);

        if (deleteEvent(hostEmail, booking.getGSuiteId(), GeneralUtility.isGoogleResource(hostEmail))) {
            booking.setBookingStatus(new BookingStatus(BookingStatus.STATUS_CANCELLED, cancelType));
            response.addSuccessBooking(booking);
        } else {
            response.addFailedBooking(booking);
        }

        return response;
    }

    /**
     * Method to list events using calendarId
     *
     * @return List of Events
     */
    public List<Event> listEvents(UserReservationSearchRequest userReservationSearchRequest, ScheduleHolder scheduleHolder) {
        DateTime minDateTime = null;
        DateTime maxDateTime = null;
        if(scheduleHolder == null) {
            org.joda.time.DateTime utcNow = DateTimeUtility.now(DateTimeUtility.UTC_ZONE_ID);
            org.joda.time.DateTime startDate = utcNow.withTimeAtStartOfDay();
            if (Boolean.TRUE.equals(userReservationSearchRequest.getIncludeHistoricReservations()))
                startDate = startDate.minusMonths(1);
            org.joda.time.DateTime endDate = utcNow.plusDays(VzConstants.MAX_RESERVATION_FUTURE_DAYS).withTime(23, 59, 59,
                    999);

            minDateTime = new DateTime(startDate.getMillis(), 0);
            maxDateTime = new DateTime(endDate.getMillis(), 0);
        }else {
            minDateTime = new DateTime(scheduleHolder.getStartTime().getMillis(), 0);
            maxDateTime = new DateTime(scheduleHolder.getEndTime().getMillis(), 0);
        }
        String userEmail = "";
        String userEid = null;

        if (!userReservationSearchRequest.getUser().isGoogleMigrated() || UserService.isOutsideDomainUser(userReservationSearchRequest.getUser().getEmail())) {
            userEmail = AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL;
            userEid = userReservationSearchRequest.getUser().getEnterpriseId();
        } else {
            userEmail = CommonUtility.convertEmail(userReservationSearchRequest.getUser().getEmail(), environment);
        }

        return listEvents(userEmail, true, userReservationSearchRequest.getIncludeCancelledReservations(), minDateTime, maxDateTime, userEid, false);
    }

    public List<Event> listEvents(String calendarId, Boolean showSingleEvents, Boolean showDeletedEvents,
			DateTime minDateTime, DateTime maxDateTime, String userEid, boolean includeLtb) {
		List<Event> allEvents = new ArrayList<>();
		if (StringUtils.isNotBlank(calendarId) && minDateTime != null && maxDateTime != null) {
			calendar = calendarAuthenticationService.calendarAuthentication(calendarId);
			List<String> extendedProperties = new ArrayList<>();
			if (userEid != null) {
				extendedProperties.add(VzConstants.KEY_GSUITE_USER_EID + "=" + userEid);
			}
            if(includeLtb) {
                extendedProperties.add(VzConstants.KEY_GSUITE_LONG_TERM_BOOKING + "=" + "true");
            }
			try {
				String nextPageToken = null;
				do {
					Events events = calendar.events().list(calendarId).setTimeMin(minDateTime).setTimeMax(maxDateTime)
							.setTimeZone("UTC").setSharedExtendedProperty(extendedProperties)
							.setSingleEvents(showSingleEvents).setShowDeleted(showDeletedEvents)
							.setPageToken(nextPageToken).execute();
					allEvents.addAll(events.getItems());
					nextPageToken = events.getNextPageToken();
				} while (nextPageToken != null);
			} catch (IOException e) {
				log.error("Unable to list the events. Details : {}", e.getMessage(), e);
			}
		}
		return allEvents;
	}

    private List<Event> getInstancesOfRecurringEvent(String calendarId, String hostId, String eventId) {
        List<Event> allEvents = new ArrayList<>();
        calendar = calendarAuthenticationService.calendarAuthentication(calendarId);
        try {
            String nextPageToken = null;
            do {
                Events events = calendar.events()
                        .instances(hostId, eventId)
                        .setTimeZone("UTC")
                        .setPageToken(nextPageToken)
                        .execute();
                allEvents.addAll(events.getItems());
                nextPageToken = events.getNextPageToken();
            } while (nextPageToken != null);
        } catch (IOException e) {
            log.error("Unable to list the events. Details : {}", e.getMessage(), e);
        }
        return allEvents;
    }
    
	public List<Event> getInstancesOfRecurringEvent(String calendarId, String hostId, String eventId, DateTime minTime,
			DateTime maxTime, boolean showDeleted) throws VzGoogleException {
		calendar = calendarAuthenticationService.calendarAuthentication(calendarId);
		List<Event> allEvents;
		if (calendar != null) {
			try {
				allEvents = new ArrayList<>();
				String nextPageToken = null;
				do {
					Events events = calendar.events().instances(hostId, eventId).setShowDeleted(showDeleted)
							.setTimeMin(minTime).setTimeMax(maxTime).setTimeZone("UTC").setPageToken(nextPageToken)
							.execute();
					allEvents.addAll(events.getItems());
					nextPageToken = events.getNextPageToken();
				} while (nextPageToken != null);
			} catch (Exception e) {
				throw new VzGoogleException(e.getMessage(), e.getCause());
			}
		} else {
			throw new VzGoogleException("Unable to get the calendar instance at the moment");
		}
		return allEvents;
	}
	
	public List<Event> listResourceEvents(String calendarId, Boolean showSingleEvents, Boolean showDeletedEvents,
			DateTime minDateTime, DateTime maxDateTime) {
		List<Event> resourceEvents = new ArrayList<>();
		try {
			calendar = calendarAuthenticationService.calendarAuthentication();
			String nextPageToken = null;
			do {
				Events events = calendar.events().list(calendarId).setTimeMin(minDateTime).setTimeMax(maxDateTime)
						.setTimeZone("UTC").setSingleEvents(showSingleEvents).setShowDeleted(showDeletedEvents)
						.setPageToken(nextPageToken).execute();
				resourceEvents.addAll(events.getItems());
				nextPageToken = events.getNextPageToken();
			} while (nextPageToken != null);
		} catch (IOException e) {
			log.error("IOException occured while listing resource events. Details: {}", e.getMessage(), e);
		} catch (Exception e) {
			log.error("Exception occured while listing resource events. Details: {}", e.getMessage(), e);
		}
		return resourceEvents;
	}
	
    private ScheduleHolder getScheduleHolder(ReservationCreationRequestDto request, Resource resource) {
        ScheduleHolder scheduleHolder = ScheduleHolder.getDefaultHolder();
        if (request != null && request.getSchedule() != null) {
            if (!StringUtils.isEmpty(request.getSchedule().getTimeZone())) {
                scheduleHolder = scheduleProviderService.prepareSchedule(request.getSchedule());
            } else if (resource != null) {
                if (!StringUtils.isEmpty(resource.getLocation().getTimezone())) {
                    request.getSchedule()
                            .setTimeZone(resource.getLocation().getTimezone());
                    scheduleHolder = scheduleProviderService.prepareSchedule(request.getSchedule());
                } else if (resource.getId() != null) {
                    scheduleHolder = scheduleProviderService.prepareScheduleUsingResource(
                            request.getSchedule(), resource.getId());
                } else if (resource.getFloor() != null
                        && resource.getFloor().getId() != null) {
                    scheduleHolder = scheduleProviderService.prepareScheduleUsingFloor(
                            request.getSchedule(), resource.getFloor().getId());
                } else if (resource.getLocation().getId() != null) {
                    scheduleHolder = scheduleProviderService.prepareScheduleUsingLocation(
                            request.getSchedule(), resource.getLocation().getId());
                } else {
                    log.error("Unable to fetch timezone from the given resource");
                }
            } else {
                log.error("Unable to fetch timezone from the given request");
            }
        } else {
            log.error("Invalid booking/schedule request");
        }
        return scheduleHolder;
    }
    
	public Set<Event> createOrUpdateReservation(ReservationCreationRequestDto reservationDto,
			Collection<Resource> gSuiteResources, boolean autoCheckIn, String eventFrom) throws VzException {
		Set<Event> events = new HashSet<>();
		CommonUtility.transformEmails(reservationDto, environment);
		Event event = createEvent(reservationDto, gSuiteResources, autoCheckIn, eventFrom);
		try {
			Event insertedEvent;
			if (StringUtils.isEmpty(reservationDto.getgSuiteId())) {
				insertedEvent = insertEvent(event);
			} else {
				event.setId(reservationDto.getgSuiteId());
				insertedEvent = updateEvent(event, true, "createOrUpdateReservation");
			}
			if (insertedEvent == null)
				throw new VzException("Authentication failure in Google");
			if (reservationDto.isRecurrentReservation()) {
				events.addAll(waitAndCheckResponseStatusOfResourceWithRecurrence(insertedEvent));
			} else {
				Event latestEvent = waitAndCheckResponseStatusOfResource(insertedEvent);
				if(latestEvent != null && !MeetingResponseStatus.NEEDS_ACTION.getName().equals(latestEvent.getStatus()))
					events.add(latestEvent);
			}
		} catch (VzException vzg) {
			throw vzg;
		} catch (Exception e) {
			log.error("Exception occurred while making the reservation. Details: {}", e.getMessage(), e);
		}
		return events;
	}
	
	/**
	 * @param resourceCalendarId
	 * @param eventId
	 * @return The Creator's email address as the first element of the collection.
	 *         If the creator is the VZReserve SVC account, creator EID is returned
	 *         as the second element along with the SVC account's email address in
	 *         the first index position.
	 * @throws VzException
	 */
	public List<String> getCreatorDetailsFromResourceCalendar(String resourceCalendarId, String eventId) throws VzException {
		List<String> creatorDetails = new ArrayList<>();
		Event event = getEvent(resourceCalendarId, eventId, true);
		if (event != null) {
			Creator creator = event.getCreator();
			if (creator != null && StringUtils.isNotBlank(creator.getEmail())) {
				creatorDetails.add(creator.getEmail());
				if (AuthenticationCredentialCalendar.SERVICE_ACCOUNT_EMAIL.equals(creator.getEmail())
						&& GsuiteReservationService.getExtendedProperty(event, false, VzConstants.KEY_GSUITE_USER_EID) != null)
					creatorDetails.add(GsuiteReservationService.getExtendedProperty(event, false, VzConstants.KEY_GSUITE_USER_EID));
			} else {
				throw new VzException(
						"Unable to get the host details from the event. Please contact the administrator.");
			}
		} else {
			throw new VzException("Unable to access google at the moment. Please try again later.");
		}
		return creatorDetails;
	}
	
	public boolean endEvent(Event event, String deletedFrom) {
		boolean eventUpdated = false;
		try {
			Event eventToUpdate = event.clone();
			Assert.notNull(eventToUpdate, "Invalid event details provided");
			createOrUpdateExtendedProperties(eventToUpdate, false, VzConstants.KEY_GSUITE_ENDED_EARLY,
					Boolean.TRUE.toString());
            if(StringUtils.isNotEmpty(deletedFrom)) {
                createOrUpdateExtendedProperties(eventToUpdate, false, VzConstants.KEY_GSUITE_DELETED_FROM,
                        deletedFrom.toUpperCase());
            }
			org.joda.time.DateTime utcNow = DateTimeUtility.now(DateTimeUtility.UTC_ZONE_ID);
			if (CollectionUtils.isNotEmpty(eventToUpdate.getRecurrence())) {
				int delim = eventToUpdate.getRecurrence().get(0).indexOf(':');
				VzValidationUtility.isTrue(delim != -1,
						"Unable to find the ':' character that delimits the recurrence rule",
						InvalidRecurrenceRuleException.class);
				String rRuleKey = eventToUpdate.getRecurrence().get(0).substring(0, delim + 1);
				RecurrenceRule rRule = new RecurrenceRule(eventToUpdate.getRecurrence().get(0).substring(delim + 1));
				org.joda.time.DateTime possibleEventEndTime = utcNow.minusMinutes(1);
				org.joda.time.DateTime eventStartTimeInUtc = new org.joda.time.DateTime(
						eventToUpdate.getStart().getDateTime() != null
								? eventToUpdate.getStart().getDateTime().getValue()
								: eventToUpdate.getStart().getDate().getValue()).withZone(DateTimeZone.UTC);
				org.joda.time.DateTime updatedEventEndTime = (possibleEventEndTime.isBefore(eventStartTimeInUtc) || possibleEventEndTime.equals(eventStartTimeInUtc))
						? eventStartTimeInUtc.plusMinutes(1)
						: possibleEventEndTime;
				rRule.setUntil(new org.dmfs.rfc5545.DateTime(updatedEventEndTime.getMillis()));
				eventToUpdate.getRecurrence().set(0, StringUtils.join(rRuleKey, rRule.toString()));
				eventUpdated = updateEvent(eventToUpdate, true, "endEvents") != null;
				if (eventUpdated)
					endCurrentRecurringInstanceIfApplicable(eventToUpdate, deletedFrom);
			} else if (eventToUpdate.getEnd() != null
					&& (eventToUpdate.getEnd().getDate() != null || eventToUpdate.getEnd().getDateTime() != null)) {
				org.joda.time.DateTime eventEndTimeInUtc = new org.joda.time.DateTime(
						eventToUpdate.getEnd().getDateTime() != null ? eventToUpdate.getEnd().getDateTime().getValue()
								: eventToUpdate.getEnd().getDate().getValue()).withZone(DateTimeZone.UTC);
				if (eventEndTimeInUtc.isAfter(utcNow)) {
					org.joda.time.DateTime possibleEventEndTime = utcNow.minusMinutes(1);
					org.joda.time.DateTime eventStartTimeInUtc = new org.joda.time.DateTime(
							eventToUpdate.getStart().getDateTime() != null
									? eventToUpdate.getStart().getDateTime().getValue()
									: eventToUpdate.getStart().getDate().getValue()).withZone(DateTimeZone.UTC);
					org.joda.time.DateTime updatedEventEndTime = (possibleEventEndTime.isBefore(eventStartTimeInUtc) || possibleEventEndTime.equals(eventStartTimeInUtc))
							? eventStartTimeInUtc.plusMinutes(1)
							: possibleEventEndTime;
					eventToUpdate.setEnd(new EventDateTime().setDateTime(
							com.google.api.client.util.DateTime.parseRfc3339(updatedEventEndTime.toString())));
					eventUpdated = updateEvent(eventToUpdate, true, "endEvent") != null;
				}
			} else {
				log.warn("Invalid event details received to end the reservation");
			}
		} catch (InvalidRecurrenceRuleException e) {
			log.error("Invalid recurrence rule passed to cancel the recurring event. Details: {}", e.getMessage(), e);
		}
		return eventUpdated;
	}
	
	public static Event createOrUpdateExtendedProperties(Event event, boolean usePrivate, String key, String value) {
		ExtendedProperties extendedProperties = event.getExtendedProperties();
		if (extendedProperties == null)
			extendedProperties = new ExtendedProperties();
		Map<String, String> properties = usePrivate ? extendedProperties.getPrivate() : extendedProperties.getShared();
		if (properties == null) {
			properties = new HashMap<>();
			properties.put(key, value);
			if (usePrivate) {
				extendedProperties.setPrivate(properties);
			} else {
				extendedProperties.setShared(properties);
			}
		} else {
			properties.put(key, value);
		}
		event.setExtendedProperties(extendedProperties);
		return event;
	}
	
	public static String getExtendedProperty(Event event, boolean usePrivate, String key) {
		String value = null;
		ExtendedProperties extendedProperties = event.getExtendedProperties();
		if (extendedProperties != null) {
			if (usePrivate) {
				if (extendedProperties.getPrivate() != null)
					value = extendedProperties.getPrivate().get(key);
			} else {
				if (extendedProperties.getShared() != null)
					value = extendedProperties.getShared().get(key);
				// logic to check entry in private property to support backward compatibility
				if (value == null && extendedProperties.getPrivate() != null)
					value = extendedProperties.getPrivate().get(key);
			}
		}
		return value;
	}
	
	public static boolean removeExtendedProperty(Event event, boolean usePrivate, String key) {
		boolean status = false;
		ExtendedProperties extendedProperties = event.getExtendedProperties();
		if (extendedProperties != null) {
			Map<String, String> properties = usePrivate ? extendedProperties.getPrivate()
					: extendedProperties.getShared();
			if (properties != null)
				status = properties.containsKey(key) && properties.remove(key) != null;
		}
		return status;
	}
	
	private void endCurrentRecurringInstanceIfApplicable(Event parentEvent, String deletedFrom) {
		org.joda.time.DateTime eventStartTimeInUtc = new org.joda.time.DateTime(
				parentEvent.getStart().getDateTime() != null ? parentEvent.getStart().getDateTime().getValue()
						: parentEvent.getStart().getDate().getValue()).withZone(DateTimeZone.UTC);
		org.joda.time.DateTime eventEndTimeInUtc = new org.joda.time.DateTime(
				parentEvent.getEnd().getDateTime() != null ? parentEvent.getEnd().getDateTime().getValue()
						: parentEvent.getEnd().getDate().getValue()).withZone(DateTimeZone.UTC);
		try {
			org.joda.time.DateTime lastRecurringStartTime = DateTimeUtility
					.getLastRecurringInstance(parentEvent.getRecurrence().get(0).substring(6), eventStartTimeInUtc);
			org.joda.time.DateTime lastRecurringEndTime = DateTimeUtility.now(DateTimeUtility.UTC_ZONE_ID).withTime(
					eventEndTimeInUtc.getHourOfDay(), eventEndTimeInUtc.getMinuteOfHour(),
					eventEndTimeInUtc.getSecondOfMinute(), eventEndTimeInUtc.getMillisOfSecond());
			List<Event> recurringInstances = getInstancesOfRecurringEvent(parentEvent.getCreator().getEmail(),
					parentEvent.getOrganizer().getEmail(), parentEvent.getId(),
					new DateTime(lastRecurringStartTime.toDate()),
					new DateTime(lastRecurringEndTime.toDate()), false);
			if (CollectionUtils.isNotEmpty(recurringInstances)) {
				if (recurringInstances.size() > 1)
					log.info(
							"Expected one recurring instances but found many for the given time frame. Using the first element");
				endEvent(recurringInstances.get(0), deletedFrom);
			}
		} catch (InvalidRecurrenceRuleException e) {
			log.error("Unable to parse the given recurrence rule. Details: {}", e.getMessage(), e);
		} catch (VzGoogleException e) {
			log.error("Unable to get the recurring instances from google. Details: {}", e.getMessage(), e);
		}
	}

	public static Boolean isPastEvent(Event event) {
		Boolean pastEvent = null;
		try {
			Assert.notNull(event, "Invalid event details passed as argument");
			if (CollectionUtils.isNotEmpty(event.getRecurrence())) {
				List<org.joda.time.DateTime> upcomingInstances = getUpcomingRecurringInstances(event);
				if (upcomingInstances != null)
					pastEvent = CollectionUtils.isEmpty(upcomingInstances);
			} else if (event.getStart() != null
					&& (event.getStart().getDate() != null || event.getStart().getDateTime() != null)
					&& event.getEnd() != null
					&& (event.getEnd().getDate() != null || event.getEnd().getDateTime() != null)) {
				org.joda.time.DateTime utcNow = DateTimeUtility.now(DateTimeUtility.UTC_ZONE_ID);
				org.joda.time.DateTime eventStartTimeInUtc = new org.joda.time.DateTime(
						event.getStart().getDateTime() != null ? event.getStart().getDateTime().getValue()
								: event.getStart().getDate().getValue()).withZone(DateTimeZone.UTC);
				org.joda.time.DateTime eventEndTimeInUtc = new org.joda.time.DateTime(
						event.getEnd().getDateTime() != null ? event.getEnd().getDateTime().getValue()
								: event.getEnd().getDate().getValue()).withZone(DateTimeZone.UTC);
				pastEvent = (eventStartTimeInUtc.isBefore(utcNow)) && (eventEndTimeInUtc.isBefore(utcNow));
			}
		} catch (Exception e) {
			logger.error("Exception occured while validating the event. Details :{}", e.getMessage(), e);
		}
		return pastEvent;
	}

	public static Boolean isOngoingEvent(Event event) {
		Boolean ongoingEvent = null;
		try {
			Assert.notNull(event, "Invalid event details passed as argument");
			if (event.getStart() != null
					&& (event.getStart().getDate() != null || event.getStart().getDateTime() != null)) {
				org.joda.time.DateTime utcNow = DateTimeUtility.now(DateTimeUtility.UTC_ZONE_ID);
				org.joda.time.DateTime eventStartTimeInUtc = new org.joda.time.DateTime(
						event.getStart().getDateTime() != null ? event.getStart().getDateTime().getValue()
								: event.getStart().getDate().getValue()).withZone(DateTimeZone.UTC);
				if (CollectionUtils.isNotEmpty(event.getRecurrence())) {
					List<org.joda.time.DateTime> upcomingInstances = getUpcomingRecurringInstances(event);
					if (upcomingInstances != null)
						ongoingEvent = eventStartTimeInUtc.isBefore(utcNow)
								&& CollectionUtils.isNotEmpty(upcomingInstances);
				} else if (event.getEnd() != null
						&& (event.getEnd().getDate() != null || event.getEnd().getDateTime() != null)) {
					org.joda.time.DateTime eventEndTimeInUtc = new org.joda.time.DateTime(
							event.getEnd().getDateTime() != null ? event.getEnd().getDateTime().getValue()
									: event.getEnd().getDate().getValue()).withZone(DateTimeZone.UTC);
					ongoingEvent = (utcNow.equals(eventStartTimeInUtc) || utcNow.isAfter(eventStartTimeInUtc))
							&& (utcNow.equals(eventEndTimeInUtc) || utcNow.isBefore(eventEndTimeInUtc));
				}
			}
		} catch (Exception e) {
			logger.error("Exception occured while validating the event. Details :{}", e.getMessage(), e);
		}
		return ongoingEvent;
	}

	public static List<org.joda.time.DateTime> getUpcomingRecurringInstances(Event event)
			throws InvalidRecurrenceRuleException {
		List<org.joda.time.DateTime> upcomingInstances = null;
		if (event != null && CollectionUtils.isNotEmpty(event.getRecurrence())
				&& event.getRecurrence().get(0).length() > 6 && event.getStart() != null
				&& (event.getStart().getDate() != null || event.getStart().getDateTime() != null)) {
			org.joda.time.DateTime eventStartTimeInUtc = new org.joda.time.DateTime(
					event.getStart().getDateTime() != null ? event.getStart().getDateTime().getValue()
							: event.getStart().getDate().getValue()).withZone(DateTimeZone.UTC);
			upcomingInstances = DateTimeUtility.getUpcomingRecurringInstances(event.getRecurrence().get(0).substring(6),
					eventStartTimeInUtc);
		}
		return upcomingInstances;
	}
	
	public static ScheduleHolder getScheduleHolder(Event event, com.verizon.vzreserve.dto.ResourceDto resource) {
		ScheduleHolder scheduleHolder = null;
		if (event != null) {
			String timezone = "";
			if (event.getExtendedProperties() != null) {				
				String timeZoneValue = GsuiteReservationService.getExtendedProperty(event, false, VzConstants.KEY_GSUITE_TIMEZONE);
				if (timeZoneValue != null)
					timezone = timeZoneValue;
			} else if (event.getStart() != null) {
				timezone = event.getStart().getTimeZone();
			} else if (event.getEnd() != null) {
				timezone = event.getEnd().getTimeZone();
			}			
			if (StringUtils.isEmpty(timezone))
				timezone = resource != null ? resource.getLocationTimeZone() : DateTimeUtility.UTC_ZONE_ID;
			org.joda.time.DateTime eventStartTimeInUtc = new org.joda.time.DateTime(
					event.getStart().getDateTime() != null ? event.getStart().getDateTime().getValue()
							: event.getStart().getDate().getValue()).withZone(DateTimeZone.UTC);
			org.joda.time.DateTime eventEndTimeInUtc = new org.joda.time.DateTime(
					event.getEnd().getDateTime() != null ? event.getEnd().getDateTime().getValue()
							: event.getEnd().getDate().getValue()).withZone(DateTimeZone.UTC);
			scheduleHolder = new ScheduleHolder(eventStartTimeInUtc, eventEndTimeInUtc, timezone);
		}
		return scheduleHolder;
	}

	public Event validateAndCheckIn(Event event, String hostEid, Collection<Resource> resources)
			throws VzValidationException {
		validateAndPutCheckInProperties(event, hostEid, resources);
		return updateEvent(event, true, "validateAndCheckIn");
	}

	public void validateAndPutCheckInProperties(Event event, String hostEid, Collection<Resource> resources)
			throws VzValidationException {
		String checkInAllResources = systemPropertyService
				.getPropertyValue(VzConstants.SYS_PROP_GSUITE_CHECK_IN_ALL_RESOURCES);
		Set<String> resourcesCheckedIn = checkInResources(event, hostEid, resources, checkInAllResources);
		VzValidationUtility.isTrue(CollectionUtils.isNotEmpty(resourcesCheckedIn), VzValidationException.class,
				"Unable to find the requested resources in the reservation [or] the resources might have already been checked in!",
				HttpStatus.BAD_REQUEST);
		String alreadyCheckedInGlobally = GsuiteReservationService.getExtendedProperty(event, false,
				VzConstants.KEY_GSUITE_GLOBAL_CHECK_IN);
		if (StringUtils.isNotBlank(alreadyCheckedInGlobally)
				&& Boolean.TRUE.equals(Boolean.valueOf(alreadyCheckedInGlobally))) {
			GsuiteReservationService.createOrUpdateExtendedProperties(event, false,
					VzConstants.KEY_GSUITE_GLOBAL_LAST_CHECK_IN_TIME,
					DateTimeUtility.now(DateTimeUtility.UTC_ZONE_ID).toString());
		} else {
			GsuiteReservationService.createOrUpdateExtendedProperties(event, false,
					VzConstants.KEY_GSUITE_CHECK_IN_ALL_RESOURCES,
					String.valueOf(VzConstants.YES.equals(checkInAllResources)));
			GsuiteReservationService.createOrUpdateExtendedProperties(event, false, VzConstants.KEY_GSUITE_GLOBAL_CHECK_IN,
					Boolean.TRUE.toString());
			GsuiteReservationService.createOrUpdateExtendedProperties(event, false,
					VzConstants.KEY_GSUITE_GLOBAL_FIRST_CHECK_IN_TIME,
					DateTimeUtility.now(DateTimeUtility.UTC_ZONE_ID).toString());
			GsuiteReservationService.createOrUpdateExtendedProperties(event, false,
					VzConstants.KEY_GSUITE_GLOBAL_LAST_CHECK_IN_TIME,
					DateTimeUtility.now(DateTimeUtility.UTC_ZONE_ID).toString());
		}
	}

	private Set<String> checkInResources(Event event, String hostEid, Collection<Resource> resources,
			String checkInAllResources) {
		Map<String, Entry<Integer, Resource>> resourceDetailsMap = CollectionUtils.isNotEmpty(resources)
				? resources.stream()
						.collect(Collectors.toMap(Resource::getEmail, r -> new AbstractMap.SimpleEntry<>(r.getId(), r)))
				: Collections.emptyMap();
		return event.getAttendees().stream().filter(Objects::nonNull).filter(EventAttendee::isResource)
				.filter(eventAttendee -> {
					boolean status = false;
					String alreadyCheckedIn = GsuiteReservationService.getExtendedProperty(event, false,
							StringUtils.join(VzConstants.KEY_GSUITE_CHECKED_IN_RESOURCE_CALENDAR_ID,
									eventAttendee.getEmail().hashCode()));
					status = alreadyCheckedIn == null || StringUtils.isBlank(alreadyCheckedIn)
							|| Boolean.FALSE.equals(Boolean.valueOf(alreadyCheckedIn));
					return status;
				}).map(eventAttendee -> {
					String resourceEmail = null;
					if (VzConstants.YES.equals(checkInAllResources)
							|| resourceDetailsMap.containsKey(eventAttendee.getEmail()))
						eventAttendee.setComment(VzConstants.KEY_GSUITE_EVENT_ATTENDEE_CHECK_IN_LABEL);
					if (resourceDetailsMap.containsKey(eventAttendee.getEmail())) {
						resourceEmail = eventAttendee.getEmail();
						GsuiteReservationService.createOrUpdateExtendedProperties(event, false,
								StringUtils.join(VzConstants.KEY_GSUITE_CHECKED_IN_RESOURCE_CALENDAR_ID,
										resourceEmail.hashCode()),
								Boolean.TRUE.toString());
						GsuiteReservationService.createOrUpdateExtendedProperties(event, false,
								StringUtils.join(VzConstants.KEY_GSUITE_CHECKED_IN_RESOURCE_META,
										resourceEmail.hashCode()),
								convertObjectToJsonString(new ExtendedPropertyWrapper()
										.withCheckedInResourceEmail(resourceEmail)
										.withCheckedInResourceId(resourceDetailsMap.get(resourceEmail).getKey())
										.withCheckedInTime(DateTimeUtility.now(DateTimeUtility.UTC_ZONE_ID).toString())
										.withCheckedInUserEid(hostEid)));
					}
					return resourceEmail;
				}).filter(Objects::nonNull).collect(Collectors.toSet());
	}

	public <T> String convertObjectToJsonString(T object) {
		String json = "";
		try {
			json = objectMapper.writeValueAsString(object);
		} catch (JsonProcessingException e) {
			log.error("Exception occured while exporting data to JSON. Details: {}", e.getMessage(), e);
		}
		return json;
	}

	public <T> T convertJsonStringToObject(String json, TypeReference<T> typeRef) {
		T parsedObject = null;
		try {
			parsedObject = objectMapper.readValue(json, typeRef);
		} catch (JsonProcessingException e) {
			log.error("Exception occured while exporting data to JSON. Details: {}", e.getMessage(), e);
		}
		return parsedObject;
	}

    public CallStatusDto updateResponseStatus(String email, String eventId, String meetingResponseStatus) {
        CallStatusDto callStatusDto = new CallStatusDto();

        try {
            Event eventToBeUpdated = getEvent(email, eventId, GeneralUtility.isGoogleResource(email));

            eventToBeUpdated.getAttendees().stream().filter(e -> e.getEmail() != null && e.getEmail().equals(email)).forEach(e ->
                    e.setResponseStatus(MeetingResponseStatus.getByAcronym(meetingResponseStatus).getName()));
            eventToBeUpdated = updateEvent(eventToBeUpdated, true, "updateResponseStatus");
            eventToBeUpdated.getAttendees().stream().filter(e -> e.getEmail() != null && e.getEmail().equals(email)).forEach(e -> {
                if (e.getResponseStatus().equals(MeetingResponseStatus.getByAcronym(meetingResponseStatus).getName()))
                    callStatusDto.setSuccessAndMessage(true, "Successfully updated the event!");
                else
                    callStatusDto.setSuccessAndMessage(false, "Event not updated!");
            });
        } catch (Exception e) {
            log.error("Exception occured while exporting data to JSON. Details: {}", e.getMessage(), e);
            callStatusDto.setSuccessAndMessage(false, "Event not updated!");
        }
        return callStatusDto;
    }
    
}
