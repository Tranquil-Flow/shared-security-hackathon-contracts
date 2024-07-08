// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;
/**
 * @author Othentic Labs LTD.
 * @notice Terms of Service: https://www.othentic.xyz/terms-of-service
 */
import { IAvsLogic } from "./IAvsLogic.sol";

interface IAttestationCenter {

    enum OperatorStatus
    {
        INACTIVE,
        ACTIVE
    }

    enum PaymentStatus {
        REDEEMED,
        COMMITTED,
        CHALLENGED
    }
    
    struct PaymentDetails {
        address wallet;
        uint256 lastPaidTaskNumber;
        uint256 feeToClaim;
        PaymentStatus paymentStatus;
    }

    struct PaymentRequestMessage {
        address wallet;
        uint256 feeToClaim;
    }

    struct TaskInfo {
        string proofOfTask;
        bytes data;
        address taskPerformer;
        uint16 taskDefinitionId;
    }
    event OperatorRegisteredToNetwork(address operator, uint256 shares);
    event OperatorUnregisteredFromNetwork(uint256 operatorId);
    event OperatorSharesModified(address operator, uint256 shares);
    event PaymentRequested(address operator, uint256 lastPaidTaskNumber, uint256 feeToClaim);
    event PaymentsRequested(PaymentRequestMessage[] operators, uint256 lastPaidTaskNumber);
    event ClearPaymentRejected(address operator, uint256 requestedTaskNumber, uint256 requestedAmountClaimed);
    event TaskSubmited(address operator, uint32 taskNumber, string proofOfTask, bytes data, uint16 taskDefinitionId);
    event TaskRejected(address operator, uint32 taskNumber, string proofOfTask, bytes data, uint16 taskDefinitionId);

    function taskNumber() external view returns (uint32);

    function baseRewardFee() external view returns (uint256);

    function numOfOperators() external view returns (uint256);

    function getOperatorPaymentDetail(uint256 _operatorId) external view returns (PaymentDetails memory);

    function operatorsIdsByAddress(address _operator) external view returns (uint256);

    function avsLogic() external view returns (IAvsLogic); 

    function submitTask(TaskInfo calldata _taskInfo, bool _isApproved, bytes calldata _tpSignature, uint256[2] calldata _taSignature, uint256[] calldata _operatorIds) external;

    function requestPayment(uint256 _operatorId) external;

    function requestBatchPayment() external;

    function registerToNetwork(address _operator, uint256 _numOfShares, uint256[4] memory _blsKey) external;

    function unRegisterOperatorFromNetwork(address _operator) external;

    function modifyNumOfShares (uint256 _operatorId, uint256 _numOfShares) external;

    function clearPayment(address _operator, uint256 _lastPaidTaskNumber, uint256 _amountClaimed) external;

    function clearBatchPayment(PaymentRequestMessage[] memory _operators, uint256 _lastPaidTaskNumber) external;

    function transferAvsGovernanceMultisig(address _newAvsGovernanceMultisig) external;

    function setAvsLogic(IAvsLogic _avsLogic) external;
}